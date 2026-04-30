use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct Notification {
    pub id: Uuid,
    pub user_id: Uuid,
    pub title_vi: String,
    pub title_en: String,
    pub body_vi: String,
    pub body_en: String,
    pub is_read: bool,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct NotificationPayload {
    pub user_id: String,
    pub title_vi: String,
    pub title_en: String,
    pub body_vi: String,
    pub body_en: String,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
