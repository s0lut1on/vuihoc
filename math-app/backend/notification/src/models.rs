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

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct PushSubscription {
    pub id: Uuid,
    pub user_id: Uuid,
    pub fcm_token: String,
    pub platform: String,
    pub is_active: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Deserialize, ToSchema)]
pub struct SubscribeRequest {
    pub fcm_token: String,
    pub platform: String,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct NotificationPreferences {
    pub id: Uuid,
    pub user_id: Uuid,
    pub daily_reminder_enabled: bool,
    pub reminder_hour: i32,
    pub timezone: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Deserialize, ToSchema)]
pub struct UpdatePreferencesRequest {
    pub daily_reminder_enabled: Option<bool>,
    pub reminder_hour: Option<i32>,
    pub timezone: Option<String>,
}

#[derive(Serialize, ToSchema)]
pub struct SubscriptionStatus {
    pub subscribed: bool,
    pub platform: Option<String>,
}

#[derive(Serialize, ToSchema)]
pub struct ReminderResult {
    pub sent: usize,
    pub failed: usize,
    pub total: usize,
    pub reason: Option<String>,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
