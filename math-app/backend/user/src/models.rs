use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

#[derive(Serialize, sqlx::FromRow, Clone, utoipa::ToSchema)]
pub struct User {
    pub id: Uuid,
    pub email: Option<String>,
    pub name: String,
    pub persona: String,
    pub avatar: String,
    pub streak_days: i32,
    pub gems: i32,
    pub total_lessons: i32,
    pub total_stars: i32,
    pub locale: String,
    pub subscription_tier: String,
    pub classroom_code: Option<String>,
    pub grade: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, utoipa::ToSchema)]
pub struct CreateUserRequest {
    pub name: String,
    pub persona: String,
    pub locale: Option<String>,
    pub grade: Option<i32>,
}

#[derive(Serialize, Deserialize, utoipa::ToSchema)]
pub struct UpdateGradeRequest {
    pub grade: i32,
}

#[derive(Serialize, Deserialize, utoipa::ToSchema)]
pub struct JoinClassroomRequest {
    pub classroom_code: String,
}

#[derive(Serialize, sqlx::FromRow, Clone, utoipa::ToSchema)]
pub struct LeaderboardEntry {
    pub id: Uuid,
    pub name: String,
    pub avatar: String,
    pub weekly_stars: i64,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
