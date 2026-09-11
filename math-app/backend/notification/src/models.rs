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
    pub parent_email: Option<String>,
    pub email_reports_enabled: bool,
    pub report_frequency: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Deserialize, ToSchema)]
pub struct UpdatePreferencesRequest {
    pub daily_reminder_enabled: Option<bool>,
    pub reminder_hour: Option<i32>,
    pub timezone: Option<String>,
    pub parent_email: Option<String>,
    pub email_reports_enabled: Option<bool>,
    pub report_frequency: Option<String>,
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

/// Aggregated progress data for email reports.
#[derive(Serialize, ToSchema, Clone)]
pub struct ReportData {
    pub user_id: Uuid,
    pub user_name: String,
    pub locale: String,
    pub period_label: String,
    pub lessons_completed_period: i32,
    pub lessons_completed_total: i32,
    pub total_stars: i32,
    pub current_streak: i32,
    pub best_streak: i32,
    pub total_score: i32,
    pub correct_count: i32,
    pub new_achievements: Vec<String>,
    pub subjects: Vec<SubjectProgress>,
}

#[derive(Serialize, ToSchema, Clone)]
pub struct SubjectProgress {
    pub subject_id: String,
    pub name_vi: String,
    pub name_en: String,
    pub icon: String,
    pub completed: i32,
    pub stars: i32,
    pub completion_pct: f64,
}

#[derive(Serialize, ToSchema)]
pub struct ReportSendResult {
    pub sent: usize,
    pub failed: usize,
    pub skipped: usize,
    pub reason: Option<String>,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
