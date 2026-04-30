use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;

#[derive(Serialize, FromRow, ToSchema, Clone)]
pub struct MediaAsset {
    pub id: String,
    pub url: String,
    pub mime_type: String,
    pub file_size: i64,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct UploadUrlRequest {
    pub filename: String,
    pub mime_type: String,
}

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
}
