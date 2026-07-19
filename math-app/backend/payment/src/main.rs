use axum::{routing::{get, post}, Router};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;

pub use models::{AppState, CheckoutResponse, CreateCheckoutRequest, Subscription, SubscriptionStatus};

#[derive(OpenApi)]
#[openapi(components(schemas(CheckoutResponse, CreateCheckoutRequest, Subscription, SubscriptionStatus)))]
pub struct ApiDoc;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn subscription_fields_present() {
        let s = Subscription {
            id: uuid::Uuid::new_v4(),
            user_id: uuid::Uuid::new_v4(),
            stripe_subscription_id: Some("sub_123".to_string()),
            stripe_customer_id: Some("cus_123".to_string()),
            tier: "premium".to_string(),
            status: "active".to_string(),
            current_period_start: chrono::Utc::now(),
            current_period_end: Some(chrono::Utc::now()),
            created_at: chrono::Utc::now(),
            updated_at: chrono::Utc::now(),
        };
        assert_eq!(s.tier, "premium");
        assert_eq!(s.status, "active");
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://postgres:postgres@localhost:5432/payment_db".to_string()
    });
    let db = sqlx::PgPool::connect(&db_url)
        .await
        .expect("DB connection failed");
    sqlx::migrate!("./migrations").run(&db).await.ok();

    let state = AppState { db };

    let app = Router::new()
        .route("/api/payments/health", get(handlers::health))
        .route(
            "/api/payments/create-checkout",
            post(handlers::create_checkout_session),
        )
        .route("/api/payments/webhook", post(handlers::stripe_webhook))
        .route(
            "/api/payments/status",
            get(handlers::get_subscription_status),
        )
        .merge(
            SwaggerUi::new("/api/payments/swagger-ui")
                .url("/api/payments/openapi.json", ApiDoc::openapi()),
        )
        .with_state(state)
        .layer(CorsLayer::permissive());

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".to_string())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    tracing::info!("Payment service listening on {}", addr);
    axum::serve(listener, app).await.unwrap();
}
