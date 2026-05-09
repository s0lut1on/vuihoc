use crate::models::{AppState, MediaAsset, UploadUrlRequest};
use axum::{extract::State, Json};

pub async fn list_media(State(state): State<AppState>) -> shared::ApiResponse<Vec<MediaAsset>> {
    let rows = sqlx::query_as::<_, MediaAsset>("SELECT * FROM media_assets LIMIT 50")
        .fetch_all(&state.db)
        .await;
    match rows {
        Ok(data) => shared::ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in list_media: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn upload_media_url(
    State(state): State<AppState>,
    Json(body): Json<UploadUrlRequest>,
) -> shared::ApiResponse<MediaAsset> {
    let id = uuid::Uuid::new_v4().to_string();
    let minio_endpoint =
        std::env::var("MINIO_ENDPOINT").unwrap_or_else(|_| "minio:9000".to_string());
    let url = format!("http://{}/math-app/{}", minio_endpoint, &id);

    let result = sqlx::query_as::<_, MediaAsset>(
        "INSERT INTO media_assets (id, url, mime_type, file_size) VALUES ($1, $2, $3, 0) RETURNING *"
    )
    .bind(&id)
    .bind(&url)
    .bind(&body.mime_type)
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(m) => shared::ApiResponse::ok(m),
        Err(_) => shared::ApiResponse::err("Failed to store media"),
    }
}

pub async fn health() -> shared::ApiResponse<shared::HealthResponse> {
    shared::ApiResponse::ok(shared::health("media"))
}
