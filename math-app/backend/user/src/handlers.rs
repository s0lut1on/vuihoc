use axum::{extract::State, Json};
use chrono::Utc;

use crate::models::{AppState, CreateUserRequest, User};

pub async fn get_user(State(state): State<AppState>) -> shared::ApiResponse<User> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users LIMIT 1")
        .fetch_optional(&state.db)
        .await;
    match user {
        Ok(Some(u)) => shared::ApiResponse::ok(u),
        Ok(None) => shared::ApiResponse::ok(User {
            id: uuid::Uuid::new_v4(),
            name: "Be Minh Anh".to_string(),
            persona: "achiever".to_string(),
            avatar: "🐸".to_string(),
            streak_days: 7,
            gems: 248,
            total_lessons: 12,
            total_stars: 3,
            created_at: Utc::now(),
        }),
        Err(e) => {
            tracing::error!("Database error in get_user: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn create_user(
    State(state): State<AppState>,
    Json(body): Json<CreateUserRequest>,
) -> shared::ApiResponse<User> {
    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (name, persona, avatar, streak_days, gems, total_lessons, total_stars) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *",
    )
    .bind(&body.name)
    .bind(&body.persona)
    .bind("🐸")
    .bind(0i32)
    .bind(0i32)
    .bind(0i32)
    .bind(0i32)
    .fetch_one(&state.db)
    .await;
    match user {
        Ok(u) => shared::ApiResponse::ok(u),
        Err(e) => {
            tracing::error!("Database error in create_user: {}", e);
            shared::ApiResponse::err("Failed to create user")
        }
    }
}

pub async fn health() -> shared::ApiResponse<shared::HealthResponse> {
    shared::ApiResponse::ok(shared::health("user"))
}
