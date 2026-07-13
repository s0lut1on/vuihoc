use axum::{routing::get, Router};
use sqlx::PgPool;
use std::net::SocketAddr;
use std::path::PathBuf;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;

use models::{
    ApiExercise, ApiLesson, AppState, CurriculumSubject, LessonSummary, SubjectSummary,
};

#[derive(OpenApi)]
#[openapi(components(schemas(CurriculumSubject, ApiLesson, ApiExercise, SubjectSummary, LessonSummary)))]
pub struct ApiDoc;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://content_user:content_pass@content-db:5432/content_db".to_string()
    });

    let db = match PgPool::connect(&db_url).await {
        Ok(pool) => {
            tracing::info!("Connected to content database");
            let migration_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("migrations");
            match sqlx::migrate::Migrator::new(migration_dir).await {
                Ok(migrator) => {
                    if let Err(e) = migrator.run(&pool).await {
                        tracing::warn!("Migration failed ({}), continuing with existing schema", e);
                    }
                }
                Err(e) => {
                    tracing::warn!("Failed to load migrator ({}), skipping migrations", e);
                }
            }
            pool
        }
        Err(e) => {
            tracing::warn!("DB connection failed ({}), continuing without DB", e);
            panic!("Content service requires database connection");
        }
    };

    let state = AppState { db };

    let protected = Router::new()
        .route("/api/content/curriculum", get(handlers::curriculum))
        .route("/api/content/subjects", get(handlers::subjects))
        .route(
            "/api/content/subject/:id/lessons",
            get(handlers::get_subject_lessons),
        )
        .route("/api/content/lesson/:id", get(handlers::get_lesson))
        .route_layer(axum::middleware::from_fn(shared::auth_middleware));

    let app = Router::new()
        .route("/api/content/health", get(handlers::health))
        .merge(protected)
        .merge(
            SwaggerUi::new("/api/content/swagger-ui")
                .url("/api/content/openapi.json", ApiDoc::openapi()),
        )
        .layer(CorsLayer::permissive())
        .with_state(state);

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
    fn get_curriculum_static_returns_three_subjects() {
        let curriculum = models::get_curriculum_static();
        assert_eq!(curriculum.len(), 3);
        assert_eq!(curriculum[0].subject_id, "numbers");
        assert_eq!(curriculum[1].subject_id, "geometry");
        assert_eq!(curriculum[2].subject_id, "logic");
    }

    #[test]
    fn numbers_has_one_lesson() {
        let curriculum = models::get_curriculum_static();
        let numbers = curriculum
            .iter()
            .find(|s| s.subject_id == "numbers")
            .unwrap();
        assert_eq!(numbers.lessons.len(), 1);
    }

    #[test]
    fn lesson_first_has_one_exercise() {
        let curriculum = models::get_curriculum_static();
        let first_lesson = &curriculum[0].lessons[0];
        assert_eq!(first_lesson.id, "lesson_n1");
        assert_eq!(first_lesson.exercises.len(), 1);
        let ex = &first_lesson.exercises[0];
        assert_eq!(ex.options[1], "5");
        assert_eq!(ex.correct, 1);
    }

    #[test]
    fn subject_summary_matches_content() {
        let curriculum = models::get_curriculum_static();
        let summaries: Vec<_> = curriculum
            .iter()
            .map(|s| models::SubjectSummary {
                id: s.subject_id.clone(),
                name_vi: s.subject_vi.clone(),
                name_en: s.subject_en.clone(),
                icon: s.subject_icon.clone(),
                color: s.subject_color.clone(),
                lesson_count: s.lessons.len() as i64,
            })
            .collect();
        assert_eq!(summaries[0].lesson_count, 1);
        assert_eq!(summaries[0].name_vi, "S\u{1ed1} h\u{1ecd}c");
    }
}
