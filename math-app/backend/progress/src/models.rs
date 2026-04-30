use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct Progress {
    pub user_id: uuid::Uuid,
    pub lesson_id: String,
    pub completed: bool,
    pub stars: i32,
    pub attempts: i32,
    pub updated_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct ProgressUpdate {
    pub user_id: String,
    pub lesson_id: String,
    pub stars: i32,
    pub completed: bool,
}

#[derive(Serialize, ToSchema)]
pub struct Streak {
    pub current_streak: i32,
    pub best_streak: i32,
    pub last_activity: DateTime<Utc>,
}

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
}
