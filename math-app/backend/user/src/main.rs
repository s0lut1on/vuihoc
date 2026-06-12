use axum::{
    routing::{get, post},
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;

#[derive(OpenApi)]
#[openapi(components(schemas(models::User, models::CreateUserRequest, models::UpdateGradeRequest)))]
pub struct ApiDoc;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://user_user:user_pass@user-db:5432/user_db".to_string());
    let db = sqlx::PgPool::connect(&db_url)
        .await
        .expect("DB connection failed");

    sqlx::migrate!("./migrations").run(&db).await.ok();

    let state = models::AppState { db };

    let protected = Router::new()
        .route(
            "/api/users",
            get(handlers::get_user).post(handlers::create_user),
        )
        .route("/api/users/me", get(handlers::get_user))
        .route("/api/users/:id", get(handlers::get_user_by_id))
        .route("/api/users/classroom/join", post(handlers::join_classroom))
        .route(
            "/api/users/classroom/leave",
            post(handlers::leave_classroom),
        )
        .route(
            "/api/users/classroom/leaderboard",
            get(handlers::get_leaderboard),
        )
        .route("/api/users/grade", post(handlers::update_grade))
        .route_layer(axum::middleware::from_fn(shared::auth_middleware));

    let app = Router::new()
        .route("/api/users/health", get(handlers::health))
        .merge(protected)
        .merge(
            SwaggerUi::new("/api/users/swagger-ui")
                .url("/api/users/openapi.json", ApiDoc::openapi()),
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_fields_present() {
        let u = models::User {
            id: uuid::Uuid::new_v4(),
            email: None,
            name: "Be An".to_string(),
            persona: "achiever".to_string(),
            avatar: "🐸".to_string(),
            streak_days: 5,
            gems: 100,
            total_lessons: 10,
            total_stars: 2,
            locale: "vi_VN".to_string(),
            subscription_tier: "free".to_string(),
            classroom_code: None,
            grade: 1,
            created_at: chrono::Utc::now(),
        };
        assert_eq!(u.name, "Be An");
        assert!(u.streak_days >= 0);
    }

    #[test]
    fn create_user_request_serde_roundtrip() {
        let req = models::CreateUserRequest {
            name: "An".into(),
            persona: "achiever".into(),
            locale: Some("vi".into()),
            grade: None,
        };
        let json = serde_json::to_string(&req).unwrap();
        assert!(json.contains("achiever"));
    }
}
