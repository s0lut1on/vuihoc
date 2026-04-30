use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Serialize, sqlx::FromRow, Clone, utoipa::ToSchema)]
pub struct User {
    pub id: Uuid,
    pub name: String,
    pub persona: String,
    pub avatar: String,
    pub streak_days: i32,
    pub gems: i32,
    pub total_lessons: i32,
    pub total_stars: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, utoipa::ToSchema)]
pub struct CreateUserRequest {
    pub name: String,
    pub persona: String,
    pub locale: Option<String>,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
