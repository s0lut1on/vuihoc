use crate::models::{get_curriculum_static, AppState};
use axum::extract::{Path, Query, State};
use axum::response::{Html, IntoResponse};
use serde::Deserialize;
use shared::ApiResponse;

#[derive(Deserialize, Debug)]
pub struct GradeQuery {
    pub grade: Option<i32>,
}

pub async fn curriculum(
    State(state): State<AppState>,
    Query(query): Query<GradeQuery>,
) -> ApiResponse<Vec<crate::models::CurriculumSubject>> {
    let grade = query.grade.unwrap_or(1);
    match state.get_curriculum(grade).await {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::warn!("DB query failed ({}), falling back to static curriculum", e);
            ApiResponse::ok(get_curriculum_static())
        }
    }
}

pub async fn subjects(
    State(state): State<AppState>,
    Query(query): Query<GradeQuery>,
) -> ApiResponse<Vec<crate::models::SubjectSummary>> {
    let grade = query.grade.unwrap_or(1);
    match state.get_subjects(grade).await {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::warn!("DB query failed ({}), falling back to static subjects", e);
            let static_curriculum = get_curriculum_static();
            let summaries: Vec<_> = static_curriculum
                .into_iter()
                .map(|s| crate::models::SubjectSummary {
                    id: s.subject_id,
                    name_vi: s.subject_vi,
                    name_en: s.subject_en,
                    icon: s.subject_icon,
                    color: s.subject_color,
                    lesson_count: s.lessons.len() as i64,
                })
                .collect();
            ApiResponse::ok(summaries)
        }
    }
}

pub async fn get_lesson(
    State(state): State<AppState>,
    Path(lesson_id): Path<String>,
) -> ApiResponse<crate::models::ApiLesson> {
    match state.get_lesson(&lesson_id).await {
        Ok(Some(lesson)) => ApiResponse::ok(lesson),
        Ok(None) => {
            tracing::warn!("Lesson {} not found in DB", lesson_id);
            ApiResponse::err("Lesson not found")
        }
        Err(e) => {
            tracing::warn!("DB query failed ({}), trying static fallback", e);
            let static_curriculum = get_curriculum_static();
            for subject in static_curriculum {
                if let Some(lesson) = subject.lessons.into_iter().find(|l| l.id == lesson_id) {
                    return ApiResponse::ok(lesson);
                }
            }
            ApiResponse::err("Lesson not found")
        }
    }
}

/// Lightweight per-subject lesson list. Replaces the 808KB
/// `get_curriculum` call (which returns all subjects + all lessons +
/// all exercises) that the subject screen was using just to show
/// 30-50 lesson cards. Returns just lesson metadata — exercises
/// are fetched on-demand by the lesson screen.
pub async fn get_subject_lessons(
    State(state): State<AppState>,
    Path(subject_id): Path<String>,
    Query(query): Query<GradeQuery>,
) -> ApiResponse<Vec<crate::models::LessonSummary>> {
    let grade = query.grade.unwrap_or(1);
    match state.get_subject_lessons(&subject_id, grade).await {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::warn!(
                "DB query for subject {} lessons failed ({}), returning empty",
                subject_id, e
            );
            ApiResponse::ok(vec![])
        }
    }
}

/// A4-printable worksheet HTML for a lesson. Public (no auth) so
/// parents can share worksheet URLs on Zalo/Facebook without login.
pub async fn worksheet(
    State(state): State<AppState>,
    Path(lesson_id): Path<String>,
) -> impl IntoResponse {
    let lesson = sqlx::query_as::<_, crate::models::Lesson>(
        "SELECT * FROM lessons WHERE id = $1",
    )
    .bind(&lesson_id)
    .fetch_optional(&state.db)
    .await;

    let (title_vi, subject_vi, grade, exercises) = match lesson {
        Ok(Some(l)) => {
            let subj = sqlx::query_as::<_, (String, String)>(
                "SELECT name_vi, name_en FROM subjects WHERE id = $1",
            )
            .bind(&l.subject_id)
            .fetch_optional(&state.db)
            .await
            .ok()
            .flatten();
            let sv = subj.unwrap_or(("Mon hoc".into(), "Subject".into())).0;
            let db_exercises = sqlx::query_as::<_, crate::models::Exercise>(
                "SELECT * FROM exercises WHERE lesson_id = $1 ORDER BY exercise_order",
            )
            .bind(&lesson_id)
            .fetch_all(&state.db)
            .await
            .unwrap_or_default();
            (l.title_vi.clone(), sv, l.grade, db_exercises)
        }
        _ => {
            let static_curriculum = get_curriculum_static();
            for subject in &static_curriculum {
                if let Some(lesson) = subject.lessons.iter().find(|l| l.id == lesson_id) {
                    let ex_list: Vec<crate::models::Exercise> = lesson.exercises.iter().map(|ae| {
                        crate::models::Exercise {
                            id: ae.id.clone(),
                            lesson_id: lesson.id.clone(),
                            question_vi: ae.question_vi.clone(),
                            question_en: ae.question_en.clone(),
                            options: ae.options.clone(),
                            correct_index: ae.correct,
                            visual_asset: ae.visual.clone(),
                            hint_vi: ae.hint_vi.clone(),
                            hint_en: ae.hint_en.clone(),
                            exercise_order: ae.exercise_order,
                            created_at: chrono::Utc::now(),
                        }
                    }).collect();
                    return Ok(render_worksheet(lesson.title_vi.clone(), &subject.subject_vi, 1, &ex_list));
                }
            }
            return Err((axum::http::StatusCode::NOT_FOUND, "Lesson not found"));
        }
    };

    Ok(render_worksheet(title_vi, &subject_vi, grade, &exercises))
}

fn render_worksheet(
    title_vi: String,
    subject_vi: &str,
    grade: i32,
    exercises: &[crate::models::Exercise],
) -> Html<String> {
    let template_str = include_str!("../worksheet_template.html");
    let mut env = minijinja::Environment::new();
    if env.add_template("worksheet", template_str).is_err() {
        tracing::error!("Failed to add worksheet template");
        return Html("Template error".into());
    }
    let tmpl = match env.get_template("worksheet") {
        Ok(t) => t,
        Err(e) => {
            tracing::error!("Failed to get worksheet template: {}", e);
            return Html("Template error".into());
        }
    };

    let ex_list: Vec<serde_json::Value> = exercises
        .iter()
        .map(|ex| {
            let answer = ex
                .options
                .get(ex.correct_index as usize)
                .cloned()
                .unwrap_or_default();
            let va: String = if ex.visual_asset.is_empty() {
                String::new()
            } else {
                ex.visual_asset.clone()
            };
            serde_json::json!({
                "question_vi": ex.question_vi,
                "visual_asset": va,
                "options": ex.options,
                "answer": answer,
            })
        })
        .collect();

    let ctx = minijinja::Value::from_serialize(serde_json::json!({
        "lesson_title_vi": title_vi,
        "subject_vi": subject_vi,
        "grade": grade,
        "exercises": ex_list,
    }));

    match tmpl.render(ctx) {
        Ok(html) => Html(html),
        Err(e) => {
            tracing::error!("Worksheet template render error: {}", e);
            Html("Render error".into())
        }
    }
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("content"))
}

use axum::extract::Json;
use crate::models::{CreateSubjectRequest, CreateLessonRequest, CreateExerciseRequest, UpdateSubjectRequest};

pub async fn create_subject(
    State(state): State<AppState>,
    Json(body): Json<CreateSubjectRequest>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query(
        "INSERT INTO subjects (id, name_vi, name_en, description_vi, description_en, icon, color, display_order, grade_min, grade_max) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
    )
    .bind(&body.id)
    .bind(&body.name_vi)
    .bind(&body.name_en)
    .bind(&body.description_vi)
    .bind(&body.description_en)
    .bind(&body.icon)
    .bind(&body.color)
    .bind(body.display_order)
    .bind(body.grade_min)
    .bind(body.grade_max)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in create_subject: {}", e);
            ApiResponse::err("Failed to create subject")
        }
    }
}

pub async fn update_subject(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<UpdateSubjectRequest>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query(
        "UPDATE subjects SET name_vi = COALESCE($1, name_vi), name_en = COALESCE($2, name_en), description_vi = COALESCE($3, description_vi), description_en = COALESCE($4, description_en), icon = COALESCE($5, icon), color = COALESCE($6, color), display_order = COALESCE($7, display_order), grade_min = COALESCE($8, grade_min), grade_max = COALESCE($9, grade_max) WHERE id = $10",
    )
    .bind(body.name_vi)
    .bind(body.name_en)
    .bind(body.description_vi)
    .bind(body.description_en)
    .bind(body.icon)
    .bind(body.color)
    .bind(body.display_order)
    .bind(body.grade_min)
    .bind(body.grade_max)
    .bind(&id)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in update_subject: {}", e);
            ApiResponse::err("Failed to update subject")
        }
    }
}

pub async fn create_lesson(
    State(state): State<AppState>,
    Json(body): Json<CreateLessonRequest>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query(
        "INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, is_premium, grade) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
    )
    .bind(&body.id)
    .bind(&body.subject_id)
    .bind(&body.title_vi)
    .bind(&body.title_en)
    .bind(&body.description_vi)
    .bind(&body.description_en)
    .bind(body.lesson_order)
    .bind(body.difficulty)
    .bind(body.is_premium)
    .bind(body.grade)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in create_lesson: {}", e);
            ApiResponse::err("Failed to create lesson")
        }
    }
}

pub async fn update_lesson(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<CreateLessonRequest>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query(
        "UPDATE lessons SET title_vi = $1, title_en = $2, description_vi = $3, description_en = $4, lesson_order = $5, difficulty = $6, is_premium = $7, grade = $8 WHERE id = $9",
    )
    .bind(&body.title_vi)
    .bind(&body.title_en)
    .bind(&body.description_vi)
    .bind(&body.description_en)
    .bind(body.lesson_order)
    .bind(body.difficulty)
    .bind(body.is_premium)
    .bind(body.grade)
    .bind(&id)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in update_lesson: {}", e);
            ApiResponse::err("Failed to update lesson")
        }
    }
}

pub async fn delete_lesson(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query("DELETE FROM lessons WHERE id = $1")
        .bind(&id)
        .execute(&state.db)
        .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in delete_lesson: {}", e);
            ApiResponse::err("Failed to delete lesson")
        }
    }
}

pub async fn create_exercise(
    State(state): State<AppState>,
    Json(body): Json<CreateExerciseRequest>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query(
        "INSERT INTO exercises (id, lesson_id, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
    )
    .bind(&body.id)
    .bind(&body.lesson_id)
    .bind(&body.question_vi)
    .bind(&body.question_en)
    .bind(&body.options)
    .bind(body.correct_index)
    .bind(&body.visual_asset)
    .bind(&body.hint_vi)
    .bind(&body.hint_en)
    .bind(body.exercise_order)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in create_exercise: {}", e);
            ApiResponse::err("Failed to create exercise")
        }
    }
}

pub async fn update_exercise(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(body): Json<CreateExerciseRequest>,
) -> ApiResponse<serde_json::Value> {
    let result = sqlx::query(
        "UPDATE exercises SET lesson_id = $1, question_vi = $2, question_en = $3, options = $4, correct_index = $5, visual_asset = $6, hint_vi = $7, hint_en = $8, exercise_order = $9 WHERE id = $10",
    )
    .bind(&body.lesson_id)
    .bind(&body.question_vi)
    .bind(&body.question_en)
    .bind(&body.options)
    .bind(body.correct_index)
    .bind(&body.visual_asset)
    .bind(&body.hint_vi)
    .bind(&body.hint_en)
    .bind(body.exercise_order)
    .bind(&id)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "success": true })),
        Err(e) => {
            tracing::error!("DB error in update_exercise: {}", e);
            ApiResponse::err("Failed to update exercise")
        }
    }
}
