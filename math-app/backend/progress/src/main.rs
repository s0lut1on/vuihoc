mod handlers;
mod models;

use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

pub use models::*;

#[derive(OpenApi)]
#[openapi(components(schemas(
    Progress,
    ProgressUpdate,
    Streak,
    DailyLessonCount,
    DailyLimitStatus,
    Achievement,
    BadgeDefinition,
    AchievementWithDefinition,
    AchievementList,
    UserExerciseStat,
    ReviewExercise,
    ReviewSession
)))]
pub struct ApiDoc;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn progress_fields_present() {
        let p = Progress {
            user_id: uuid::Uuid::new_v4(),
            lesson_id: "lesson_001".to_string(),
            completed: true,
            stars: 3,
            attempts: 1,
            updated_at: chrono::Utc::now(),
        };
        assert_eq!(p.lesson_id, "lesson_001");
        assert_eq!(p.stars, 3);
    }

    #[test]
    fn progress_update_serde_roundtrip() {
        let update = ProgressUpdate {
            user_id: uuid::Uuid::new_v4().to_string(),
            lesson_id: "lesson_002".into(),
            stars: 2,
            completed: false,
        };
        let json = serde_json::to_string(&update).unwrap();
        assert!(json.contains("lesson_002"));
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://progress_user:progress_pass@progress-db:5432/progress_db".to_string()
    });
    let db = sqlx::PgPool::connect(&db_url)
        .await
        .expect("DB connection failed");
    sqlx::migrate!("./migrations").run(&db).await.ok();

    let state = models::AppState { db };
    let protected = Router::new()
        .route("/api/progress/:user_id", get(handlers::get_user_progress))
        .route(
            "/api/progress/streak/:user_id",
            get(handlers::get_user_streak),
        )
        .route(
            "/api/progress/daily-limit/:user_id",
            get(handlers::get_daily_limit),
        )
        .route(
            "/api/progress/achievements/:user_id",
            get(handlers::get_user_achievements),
        )
        .route(
            "/api/progress/achievements/:user_id/:badge_type/mark-read",
            post(handlers::mark_achievement_read),
        )
        .route("/api/progress", post(handlers::update_progress))
        .route("/api/progress/review", post(handlers::update_exercise_stat))
        .route("/api/progress/review/:user_id", get(handlers::get_review_session))
        .route_layer(axum::middleware::from_fn(shared::auth_middleware));

    let app = Router::new()
        .route("/api/progress/health", get(handlers::health))
        .merge(protected)
        .merge(
            SwaggerUi::new("/api/progress/swagger-ui")
                .url("/api/progress/openapi.json", ApiDoc::openapi()),
        )
        .with_state(state)
        .layer(CorsLayer::permissive());

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
