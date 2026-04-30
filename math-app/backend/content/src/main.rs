use axum::{routing::get, Router};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;

use models::{CurriculumSubject, Exercise, Lesson, SubjectSummary};

#[derive(OpenApi)]
#[openapi(components(schemas(CurriculumSubject, Lesson, Exercise, SubjectSummary)))]
pub struct ApiDoc;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://content_user:content_pass@content-db:5432/content_db".to_string()
    });
    if let Err(e) = sqlx::PgPool::connect(&db_url).await {
        tracing::warn!("DB connection failed ({}), continuing without DB", e);
    }

    let app = Router::new()
        .route("/api/content/health", get(handlers::health))
        .route("/api/content/curriculum", get(handlers::curriculum))
        .route("/api/content/subjects", get(handlers::subjects))
        .merge(
            SwaggerUi::new("/api/content/swagger-ui")
                .url("/api/content/openapi.json", ApiDoc::openapi()),
        )
        .layer(CorsLayer::permissive());

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn get_curriculum_returns_three_subjects() {
        let curriculum = models::get_curriculum();
        assert_eq!(curriculum.len(), 3);
        assert_eq!(curriculum[0].subject_id, "numbers");
        assert_eq!(curriculum[1].subject_id, "geometry");
        assert_eq!(curriculum[2].subject_id, "logic");
    }

    #[test]
    fn numbers_has_three_lessons() {
        let curriculum = models::get_curriculum();
        let numbers = curriculum
            .iter()
            .find(|s| s.subject_id == "numbers")
            .unwrap();
        assert_eq!(numbers.lessons.len(), 3);
    }

    #[test]
    fn lesson_first_has_one_exercise() {
        let curriculum = models::get_curriculum();
        let first_lesson = &curriculum[0].lessons[0];
        assert_eq!(first_lesson.id, "lesson_001");
        assert_eq!(first_lesson.exercises.len(), 1);
        let ex = &first_lesson.exercises[0];
        assert_eq!(ex.options[1], "5");
        assert_eq!(ex.correct, 1);
    }

    #[test]
    fn subject_summary_matches_content() {
        let curriculum = models::get_curriculum();
        let summaries: Vec<_> = curriculum
            .iter()
            .map(|s| models::SubjectSummary {
                id: s.subject_id.clone(),
                name_vi: s.subject_vi.clone(),
                name_en: s.subject_en.clone(),
                lesson_count: s.lessons.len(),
            })
            .collect();
        assert_eq!(summaries[0].lesson_count, 3);
        assert_eq!(summaries[0].name_vi, "So hoc");
    }
}
