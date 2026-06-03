use crate::models::{get_curriculum_static, AppState};
use axum::extract::{Path, Query, State};
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

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("content"))
}
