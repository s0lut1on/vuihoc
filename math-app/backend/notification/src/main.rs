use axum::{routing::{get, post}, Router};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;
mod fcm;

pub use models::{AppState, Notification, NotificationPayload, PushSubscription, NotificationPreferences, SubscribeRequest, UpdatePreferencesRequest, SubscriptionStatus};

#[derive(OpenApi)]
#[openapi(components(schemas(Notification, NotificationPayload, PushSubscription, NotificationPreferences, SubscribeRequest, UpdatePreferencesRequest, SubscriptionStatus)))]
pub struct ApiDoc;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn notification_fields_present() {
        let n = Notification {
            id: uuid::Uuid::new_v4(),
            user_id: uuid::Uuid::new_v4(),
            title_vi: "Lam bai moi nao!".to_string(),
            title_en: "New lesson!".to_string(),
            body_vi: "Bai hoc moi da mo ra".to_string(),
            body_en: "A new lesson is unlocked".to_string(),
            is_read: false,
            created_at: chrono::Utc::now(),
        };
        assert!(!n.is_read);
        assert_eq!(n.title_vi, "Lam bai moi nao!");
    }

    #[test]
    fn notification_payload_serialize() {
        let payload = NotificationPayload {
            user_id: uuid::Uuid::new_v4().to_string(),
            title_vi: "Title vi".into(),
            title_en: "Title en".into(),
            body_vi: "Body vi".into(),
            body_en: "Body en".into(),
        };
        let json = serde_json::to_string(&payload).unwrap();
        assert!(json.contains("Title vi"));
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| {
        "postgres://postgres:postgres@localhost:5432/notification_db".to_string()
    });
    let db = sqlx::PgPool::connect(&db_url)
        .await
        .expect("DB connection failed");
    sqlx::migrate!("./migrations").run(&db).await.ok();

    let state = AppState { db };

    let protected = Router::<AppState>::new()
        .route(
            "/api/notifications",
            get(handlers::list_notifications).post(handlers::send_test_notification),
        )
        .route("/api/notifications/subscribe", post(handlers::subscribe_push))
        .route("/api/notifications/unsubscribe", post(handlers::unsubscribe_push))
        .route("/api/notifications/status", get(handlers::get_subscription_status))
        .route(
            "/api/notifications/preferences",
            get(handlers::get_preferences).put(handlers::update_preferences),
        )
        .route_layer(axum::middleware::from_fn(shared::auth_middleware));

    let app = Router::<AppState>::new()
        .route("/api/notifications/health", get(handlers::health))
        .route("/api/notifications/send-report", post(handlers::send_report))
        .merge(protected)
        .merge(
            SwaggerUi::new("/api/notifications/swagger-ui")
                .url("/api/notifications/openapi.json", ApiDoc::openapi()),
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
