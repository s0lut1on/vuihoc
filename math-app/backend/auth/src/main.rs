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

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://auth_user:auth_pass@auth-db:5432/auth_db".to_string());
    let db = sqlx::PgPool::connect(&db_url)
        .await
        .expect("Failed to connect to PostgreSQL");
    sqlx::migrate!("./migrations")
        .run(&db)
        .await
        .expect("Failed to run migrations");

    let state = models::AppState { db };

    let app = Router::new()
        .route("/api/auth/health", get(handlers::health))
        .route("/api/auth/google", post(handlers::login_with_google))
        .route("/api/auth/register", post(handlers::register))
        .route("/api/auth/me", get(handlers::me))
        .merge(
            SwaggerUi::new("/api/auth/swagger-ui")
                .url("/api/auth/openapi.json", handlers::ApiDoc::openapi()),
        )
        .with_state(state)
        .layer(CorsLayer::permissive());

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!("auth-service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn models_compiles() {
        assert_eq!(
            std::mem::size_of::<models::AppState>(),
            std::mem::size_of::<models::AppState>()
        );
    }
}
