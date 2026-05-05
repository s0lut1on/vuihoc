use axum::extract::{Json, Path, State};
use std::sync::Arc;
use uuid::Uuid;

use crate::db::Db;
use crate::models::*;
use shared::ApiResponse;

#[derive(Clone)]
pub struct AppState {
    pub db: Db,
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("question_bank"))
}

pub async fn next_question(
    Path(_student_id): Path<Uuid>,
    State(_state): State<Arc<AppState>>,
) -> ApiResponse<Question> {
    ApiResponse::err("Not yet implemented: need kc_id param")
}

pub async fn submit_answer(
    Path(student_id): Path<Uuid>,
    State(state): State<Arc<AppState>>,
    Json(payload): Json<AnswerPayload>,
) -> ApiResponse<AnswerResult> {
    let question = match sqlx::query_as::<_, Question>("SELECT * FROM question WHERE id = $1")
        .bind(payload.question_id)
        .fetch_optional(state.db.pool())
        .await
    {
        Ok(Some(q)) => q,
        Ok(None) => return ApiResponse::err("Question not found"),
        Err(e) => return ApiResponse::err(&e.to_string()),
    };

    let is_correct = (payload.answer_given - question.answer).abs() < 0.01;

    let mut mastery = match sqlx::query_as::<_, BktState>(
        "SELECT * FROM mastery WHERE student_id = $1 AND kc_id = $2",
    )
    .bind(student_id)
    .bind(payload.kc_id)
    .fetch_optional(state.db.pool())
    .await
    {
        Ok(Some(m)) => m,
        Ok(None) => BktState {
            id: None,
            student_id,
            kc_id: payload.kc_id,
            ..Default::default()
        },
        Err(e) => return ApiResponse::err(&e.to_string()),
    };

    mastery = mastery.update(is_correct);

    if let Err(e) = sqlx::query(
        r#"
        INSERT INTO mastery (student_id, kc_id, p_mastery, p_learn, p_slip, p_guess, attempt_count)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        ON CONFLICT (student_id, kc_id)
        DO UPDATE SET p_mastery = EXCLUDED.p_mastery, attempt_count = EXCLUDED.attempt_count, updated_at = now()
        "#
    )
    .bind(student_id)
    .bind(payload.kc_id)
    .bind(mastery.p_mastery)
    .bind(mastery.p_learn)
    .bind(mastery.p_slip)
    .bind(mastery.p_guess)
    .bind(mastery.attempt_count)
    .execute(state.db.pool())
    .await {
        return ApiResponse::err(&e.to_string());
    }

    if let Err(e) = sqlx::query(
        "INSERT INTO response (student_id, question_id, kc_id, answer_given, is_correct, time_taken_ms) VALUES ($1, $2, $3, $4, $5, $6)"
    )
    .bind(student_id)
    .bind(payload.question_id)
    .bind(payload.kc_id)
    .bind(payload.answer_given)
    .bind(is_correct)
    .bind(payload.time_taken_ms)
    .execute(state.db.pool())
    .await {
        return ApiResponse::err(&e.to_string());
    }

    let feedback = if is_correct {
        "Chính xác! Tiếp tục phát huy."
    } else {
        "Chưa đúng. Hãy xem lại bước giải nhé!"
    };

    ApiResponse::ok(AnswerResult {
        is_correct,
        correct_answer: question.answer,
        p_mastery_new: mastery.p_mastery,
        is_mastered: mastery.is_mastered(),
        feedback: feedback.into(),
    })
}

pub async fn generate_questions(
    State(state): State<Arc<AppState>>,
    Json(req): Json<GenerateRequest>,
) -> ApiResponse<Vec<Question>> {
    let template = match sqlx::query_as::<_, QuestionTemplate>(
        "SELECT * FROM template WHERE kc_id = $1 AND difficulty = $2 AND active = true ORDER BY random() LIMIT 1"
    )
    .bind(req.kc_id)
    .bind(req.difficulty)
    .fetch_optional(state.db.pool())
    .await {
        Ok(Some(t)) => t,
        Ok(None) => return ApiResponse::err("No active template found for this KC and difficulty"),
        Err(e) => return ApiResponse::err(&e.to_string()),
    };

    let param_schema: std::collections::HashMap<String, ParamConstraint> =
        match serde_json::from_value(template.param_schema.clone()) {
            Ok(s) => s,
            Err(e) => return ApiResponse::err(&e.to_string()),
        };

    let mut questions = Vec::new();

    for _ in 0..req.count {
        let sampled = match crate::engine::sampler::sample_params(&param_schema, req.difficulty) {
            Ok(s) => s,
            Err(e) => return ApiResponse::err(&e.to_string()),
        };

        let stem =
            match crate::engine::generator::render_stem(&template.stem_template, &sampled.params) {
                Ok(s) => s,
                Err(e) => return ApiResponse::err(&e.to_string()),
            };

        let answer =
            match crate::engine::generator::eval_solution(&template.solution_expr, &sampled.params)
            {
                Ok(a) => a,
                Err(e) => return ApiResponse::err(&e.to_string()),
            };

        let error_taxonomy: Vec<String> =
            serde_json::from_value(template.error_taxonomy.clone()).unwrap_or_default();
        let distractors = crate::engine::distractor::generate_distractors(
            answer,
            &sampled.params,
            &error_taxonomy,
            3,
        );

        let question = Question {
            id: None,
            template_id: template.id.unwrap_or_else(Uuid::nil),
            kc_id: req.kc_id,
            difficulty: req.difficulty,
            stem,
            params: serde_json::to_value(&sampled.params).unwrap(),
            answer,
            distractors: serde_json::to_value(distractors).unwrap(),
            context_wrap: None,
            created_at: None,
        };

        questions.push(question);
    }

    ApiResponse::ok(questions)
}

pub async fn get_mastery(
    Path((student_id, kc_id)): Path<(Uuid, Uuid)>,
    State(state): State<Arc<AppState>>,
) -> ApiResponse<BktState> {
    let mastery =
        sqlx::query_as::<_, BktState>("SELECT * FROM mastery WHERE student_id = $1 AND kc_id = $2")
            .bind(student_id)
            .bind(kc_id)
            .fetch_optional(state.db.pool())
            .await;

    match mastery {
        Ok(Some(m)) => ApiResponse::ok(m),
        Ok(None) => ApiResponse::ok(BktState {
            id: None,
            student_id,
            kc_id,
            ..Default::default()
        }),
        Err(e) => ApiResponse::err(&e.to_string()),
    }
}
