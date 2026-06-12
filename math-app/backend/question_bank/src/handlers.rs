use axum::extract::{Json, Path, State};
use std::sync::Arc;
use uuid::Uuid;

use crate::db::Db;
use crate::llm::anthropic::{AnthropicClient, hint_contains_answer, llm_available};
use crate::models::*;
use shared::ApiResponse;
use std::collections::HashMap;
use std::sync::{Mutex, OnceLock};
use std::time::Instant;

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
        Err(e) => {
            tracing::error!("DB error in submit_answer (question lookup): {}", e);
            return ApiResponse::err("Internal server error");
        }
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
        Err(e) => {
            tracing::error!("DB error in submit_answer (mastery lookup): {}", e);
            return ApiResponse::err("Internal server error");
        }
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
        tracing::error!("DB error in submit_answer (mastery upsert): {}", e);
        return ApiResponse::err("Internal server error");
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
        tracing::error!("DB error in submit_answer (response insert): {}", e);
        return ApiResponse::err("Internal server error");
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
        Err(e) => {
            tracing::error!("DB error in generate_questions: {}", e);
            return ApiResponse::err("Internal server error")
        }
    };

    let param_schema: std::collections::HashMap<String, ParamConstraint> =
        match serde_json::from_value(template.param_schema.clone()) {
            Ok(s) => s,
            Err(e) => {
                tracing::error!("Failed to parse param_schema: {}", e);
                return ApiResponse::err("Internal server error");
            }
        };

    let mut questions = Vec::new();

    for _ in 0..req.count {
        let sampled = match crate::engine::sampler::sample_params(&param_schema, req.difficulty) {
            Ok(s) => s,
            Err(e) => {
                tracing::error!("Sampler error in generate_questions: {}", e);
                return ApiResponse::err("Internal server error");
            }
        };

        let stem =
            match crate::engine::generator::render_stem(&template.stem_template, &sampled.params) {
                Ok(s) => s,
                Err(e) => {
                    tracing::error!("Render stem error in generate_questions: {}", e);
                    return ApiResponse::err("Internal server error");
                }
            };

        let answer =
            match crate::engine::generator::eval_solution(&template.solution_expr, &sampled.params)
            {
                Ok(a) => a,
                Err(e) => {
                    tracing::error!("Eval solution error in generate_questions: {}", e);
                    return ApiResponse::err("Internal server error");
                }
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
        Err(e) => {
            tracing::error!("DB error in get_mastery: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn record_wrong(
    Path(user_id): Path<Uuid>,
    State(state): State<Arc<AppState>>,
    Json(payload): Json<RecordWrongPayload>,
) -> ApiResponse<RecordWrongResult> {
    let result = sqlx::query_as::<_, WrongAnswer>(
        r#"
        INSERT INTO wrong_answers (
            user_id, exercise_id, lesson_id, subject_id,
            question_vi, question_en, hint_vi, hint_en,
            options, correct_index, wrong_count, last_wrong_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 1, now())
        ON CONFLICT (user_id, exercise_id)
        DO UPDATE SET
            wrong_count = wrong_answers.wrong_count + 1,
            last_wrong_at = now(),
            question_vi = EXCLUDED.question_vi,
            question_en = EXCLUDED.question_en,
            hint_vi = EXCLUDED.hint_vi,
            hint_en = EXCLUDED.hint_en,
            options = EXCLUDED.options,
            correct_index = EXCLUDED.correct_index,
            lesson_id = EXCLUDED.lesson_id,
            subject_id = EXCLUDED.subject_id
        RETURNING *
        "#
    )
    .bind(user_id)
    .bind(&payload.exercise_id)
    .bind(&payload.lesson_id)
    .bind(&payload.subject_id)
    .bind(&payload.question_vi)
    .bind(&payload.question_en)
    .bind(&payload.hint_vi)
    .bind(&payload.hint_en)
    .bind(&payload.options)
    .bind(payload.correct_index)
    .fetch_one(state.db.pool())
    .await;

    match result {
        Ok(wa) => ApiResponse::ok(RecordWrongResult {
            recorded: true,
            wrong_count: wa.wrong_count,
        }),
        Err(e) => {
            tracing::error!("DB error in record_wrong: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_review(
    Path(user_id): Path<Uuid>,
    State(state): State<Arc<AppState>>,
) -> ApiResponse<ReviewList> {
    let rows = sqlx::query_as::<_, WrongAnswer>(
        "SELECT * FROM wrong_answers WHERE user_id = $1 ORDER BY wrong_count DESC, last_wrong_at DESC"
    )
    .bind(user_id)
    .fetch_all(state.db.pool())
    .await;

    match rows {
        Ok(list) => {
            let entries: Vec<ReviewEntry> = list.into_iter().map(|wa| ReviewEntry {
                exercise_id: wa.exercise_id,
                lesson_id: wa.lesson_id,
                subject_id: wa.subject_id,
                question_vi: wa.question_vi,
                question_en: wa.question_en,
                hint_vi: wa.hint_vi,
                hint_en: wa.hint_en,
                options: wa.options,
                correct_index: wa.correct_index,
                wrong_count: wa.wrong_count,
            }).collect();
            ApiResponse::ok(ReviewList { entries })
        }
        Err(e) => {
            tracing::error!("DB error in get_review: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn clear_wrong(
    Path((user_id, exercise_id)): Path<(Uuid, String)>,
    State(state): State<Arc<AppState>>,
) -> ApiResponse<shared::HealthResponse> {
    let result = sqlx::query(
        "DELETE FROM wrong_answers WHERE user_id = $1 AND exercise_id = $2"
    )
    .bind(user_id)
    .bind(&exercise_id)
    .execute(state.db.pool())
    .await;

    match result {
        Ok(_) => ApiResponse::ok(shared::health("question_bank")),
        Err(e) => {
            tracing::error!("DB error in clear_wrong: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

static HINT_CACHE: OnceLock<Mutex<HashMap<String, (String, Instant)>>> = OnceLock::new();

fn hint_cache() -> &'static Mutex<HashMap<String, (String, Instant)>> {
    HINT_CACHE.get_or_init(|| Mutex::new(HashMap::new()))
}

pub async fn get_hint(
    Json(payload): Json<HintRequest>,
) -> ApiResponse<HintResponse> {
    if !llm_available() {
        return ApiResponse::ok(HintResponse {
            hint: if payload.is_vietnamese {
                "Hãy thử lại nhé! 💪".to_string()
            } else {
                "Try again! 💪".to_string()
            },
            hint_en: "Try again! 💪".to_string(),
            from_cache: false,
        });
    }

    let cache_key = format!("{}:{:?}", payload.exercise_id, payload.answer_history);
    let now = Instant::now();

    if let Ok(cache) = hint_cache().lock() {
        if let Some((cached, ts)) = cache.get(&cache_key) {
            if now.duration_since(*ts).as_secs() < 86400 {
                return ApiResponse::ok(HintResponse {
                    hint: cached.clone(),
                    hint_en: cached.clone(),
                    from_cache: true,
                });
            }
        }
    }

    let api_key = match std::env::var("ANTHROPIC_API_KEY") {
        Ok(k) => k,
        Err(_) => return ApiResponse::err("LLM not available"),
    };

    let client = AnthropicClient::new(api_key);
    let generated = match client.generate_hint(
        &payload.question_text,
        &payload.answer_history,
        payload.is_vietnamese,
    ).await {
        Ok(text) => text,
        Err(e) => {
            tracing::error!("LLM hint generation failed: {}", e);
            return ApiResponse::ok(HintResponse {
                hint: if payload.is_vietnamese {
                    "Hãy thử lại nhé! 💪".to_string()
                } else {
                    "Try again! 💪".to_string()
                },
                hint_en: "Try again! 💪".to_string(),
                from_cache: false,
            });
        }
    };

    if hint_contains_answer(&generated, &payload.expected_answer) {
        return ApiResponse::ok(HintResponse {
            hint: if payload.is_vietnamese {
                "Hãy thử lại nhé! 💪".to_string()
            } else {
                "Try again! 💪".to_string()
            },
            hint_en: "Try again! 💪".to_string(),
            from_cache: false,
        });
    }

    if let Ok(mut cache) = hint_cache().lock() {
        cache.insert(cache_key, (generated.clone(), now));
    }

    ApiResponse::ok(HintResponse {
        hint: generated.clone(),
        hint_en: generated,
        from_cache: false,
    })
}
