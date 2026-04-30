use crate::models::{get_curriculum, CurriculumSubject, SubjectSummary};
use shared::ApiResponse;

pub async fn curriculum() -> ApiResponse<Vec<CurriculumSubject>> {
    ApiResponse::ok(get_curriculum())
}

pub async fn subjects() -> ApiResponse<Vec<SubjectSummary>> {
    let list = get_curriculum()
        .into_iter()
        .map(|s| SubjectSummary {
            id: s.subject_id,
            name_vi: s.subject_vi,
            name_en: s.subject_en,
            lesson_count: s.lessons.len(),
        })
        .collect();
    ApiResponse::ok(list)
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("content"))
}
