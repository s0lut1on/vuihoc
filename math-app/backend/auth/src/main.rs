use axum::{
    response::IntoResponse,
    routing::{get, post},
    Router,
};
use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::{Arc, Mutex};
use std::time::Instant;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;

#[derive(Clone)]
struct RateLimiter {
    hits: Arc<Mutex<HashMap<String, Vec<Instant>>>>,
    max_requests: usize,
    window_secs: u64,
}

impl RateLimiter {
    fn new(max_requests: usize, window_secs: u64) -> Self {
        Self {
            hits: Arc::new(Mutex::new(HashMap::new())),
            max_requests,
            window_secs,
        }
    }

    fn check(&self, key: &str) -> bool {
        let now = Instant::now();
        let mut map = self.hits.lock().unwrap();
        let window = std::time::Duration::from_secs(self.window_secs);
        let timestamps = map.entry(key.to_string()).or_default();
        timestamps.retain(|t| now.duration_since(*t) < window);
        if timestamps.len() >= self.max_requests {
            false
        } else {
            timestamps.push(now);
            true
        }
    }
}

async fn rate_limit_middleware(
    axum::extract::State(limiter): axum::extract::State<RateLimiter>,
    req: axum::extract::Request,
    next: axum::middleware::Next,
) -> axum::response::Response {
    let ip = req
        .headers()
        .get("x-forwarded-for")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.split(',').next())
        .unwrap_or("unknown")
        .trim()
        .to_string();

    if !limiter.check(&ip) {
        return (
            axum::http::StatusCode::TOO_MANY_REQUESTS,
            "Rate limit exceeded. Try again later.",
        )
            .into_response();
    }
    next.run(req).await
}

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
    let limiter = RateLimiter::new(10, 60);

    let login_routes = Router::new()
        .route("/api/auth/google", post(handlers::login_with_google))
        .route("/api/auth/guest", post(handlers::login_as_guest))
        .route_layer(axum::middleware::from_fn_with_state(limiter, rate_limit_middleware));

    let app = Router::new()
        .route("/api/auth/health", get(handlers::health))
        .merge(login_routes)
        .route("/api/auth/me", get(handlers::me))
        .route("/api/auth/refresh", post(handlers::refresh_token))
        .merge(
            SwaggerUi::new("/api/auth/swagger-ui")
                .url("/api/auth/openapi.json", handlers::ApiDoc::openapi()),
        )
        .with_state(state)
        .layer(shared::cors_layer());

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!("auth-service listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await.expect("Failed to bind TCP listener");
    axum::serve(listener, app).await.expect("Server error");
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
