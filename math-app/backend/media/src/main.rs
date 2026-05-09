use axum::{routing::get, Router};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod handlers;
mod models;

#[derive(OpenApi)]
#[openapi(components(schemas(models::MediaAsset, models::UploadUrlRequest)))]
pub struct ApiDoc;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:postgres@localhost:5432/media_db".to_string());
    let db = sqlx::PgPool::connect(&db_url)
        .await
        .expect("DB connection failed");
    sqlx::migrate!("./migrations").run(&db).await.ok();

    let state = models::AppState { db };

    let protected = Router::new()
        .route(
            "/api/media",
            get(handlers::list_media).post(handlers::upload_media_url),
        )
        .route_layer(axum::middleware::from_fn(shared::auth_middleware));

    let app = Router::new()
        .route("/api/media/health", get(handlers::health))
        .merge(protected)
        .merge(
            SwaggerUi::new("/api/media/swagger-ui")
                .url("/api/media/openapi.json", ApiDoc::openapi()),
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
    use chrono::Utc;
    use serde_json;

    #[test]
    fn media_asset_fields_present() {
        let m = models::MediaAsset {
            id: "img001".to_string(),
            url: "http://minio:9000/math-app/img001".to_string(),
            mime_type: "image/png".to_string(),
            file_size: 1024,
            created_at: Utc::now(),
        };
        assert_eq!(m.mime_type, "image/png");
    }

    #[test]
    fn upload_url_request_serialize() {
        let req = models::UploadUrlRequest {
            filename: "test.png".into(),
            mime_type: "image/png".into(),
        };
        let json = serde_json::to_string(&req).unwrap();
        assert!(json.contains("test.png"));
    }
}
