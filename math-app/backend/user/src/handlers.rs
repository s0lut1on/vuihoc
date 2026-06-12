use axum::{extract::{Path, State}, Extension, Json};
use chrono::Utc;

use crate::models::{AppState, CreateUserRequest, JoinClassroomRequest, User};

pub async fn get_user(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
) -> shared::ApiResponse<User> {
    let user_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(&state.db)
        .await;

    match user {
        Ok(Some(u)) => shared::ApiResponse::ok(u),
        Ok(None) => {
            tracing::info!("User not found, auto-creating default user for id={}", user_id);
            let new_user = sqlx::query_as::<_, User>(
                "INSERT INTO users (id, name, persona, avatar, streak_days, gems, total_lessons, total_stars, grade, locale, subscription_tier) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING *",
            )
            .bind(user_id)
            .bind("Bé")
            .bind("achiever")
            .bind("🐸")
            .bind(0i32)
            .bind(0i32)
            .bind(0i32)
            .bind(0i32)
            .bind(1i32)
            .bind("vi_VN")
            .bind("free")
            .fetch_one(&state.db)
            .await;

            match new_user {
                Ok(u) => shared::ApiResponse::ok(u),
                Err(e) => {
                    tracing::error!("Database error creating user: {}", e);
                    shared::ApiResponse::err("Internal server error")
                }
            }
        }
        Err(e) => {
            tracing::error!("Database error in get_user: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_user_by_id(
    State(state): State<AppState>,
    Path(user_id): Path<uuid::Uuid>,
) -> shared::ApiResponse<User> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(&state.db)
        .await;

    match user {
        Ok(Some(u)) => shared::ApiResponse::ok(u),
        Ok(None) => shared::ApiResponse::err("User not found"),
        Err(e) => {
            tracing::error!("Database error in get_user_by_id: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn create_user(
    State(state): State<AppState>,
    Json(body): Json<CreateUserRequest>,
) -> shared::ApiResponse<User> {
    let grade = body.grade.unwrap_or(1);
    let user = sqlx::query_as::<_, User>(
        "INSERT INTO users (name, persona, avatar, streak_days, gems, total_lessons, total_stars, grade) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *",
    )
    .bind(&body.name)
    .bind(&body.persona)
    .bind("🐸")
    .bind(0i32)
    .bind(0i32)
    .bind(0i32)
    .bind(0i32)
    .bind(grade)
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

pub async fn join_classroom(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
    Json(body): Json<JoinClassroomRequest>,
) -> shared::ApiResponse<serde_json::Value> {
    let user_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };

    let result = sqlx::query("UPDATE users SET classroom_code = $1 WHERE id = $2 RETURNING id")
        .bind(&body.classroom_code)
        .bind(user_id)
        .fetch_one(&state.db)
        .await;

    match result {
        Ok(_) => shared::ApiResponse::ok(serde_json::json!({"joined": true})),
        Err(e) => {
            tracing::error!("Database error in join_classroom: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn leave_classroom(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
) -> shared::ApiResponse<serde_json::Value> {
    let user_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };

    let result = sqlx::query("UPDATE users SET classroom_code = NULL WHERE id = $1")
        .bind(user_id)
        .execute(&state.db)
        .await;

    match result {
        Ok(_) => shared::ApiResponse::ok(serde_json::json!({"left": true})),
        Err(e) => {
            tracing::error!("Database error in leave_classroom: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_leaderboard(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
) -> shared::ApiResponse<Vec<crate::models::LeaderboardEntry>> {
    let user_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };

    let code: Option<String> = match sqlx::query_scalar::<_, Option<String>>(
        "SELECT classroom_code FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db)
    .await
    {
        Ok(c) => c,
        Err(e) => {
            tracing::error!("Database error in get_leaderboard: {}", e);
            return shared::ApiResponse::err("Internal server error");
        }
    };

    let code = match code {
        Some(c) => c,
        None => return shared::ApiResponse::ok(vec![]),
    };

    let rows = sqlx::query_as::<_, crate::models::LeaderboardEntry>(
        "SELECT u.id, u.name, u.avatar, COALESCE(SUM(p.stars), 0) as weekly_stars \
         FROM users u \
         LEFT JOIN progress.progress p ON u.id = p.user_id \
         AND p.updated_at >= NOW() - INTERVAL '7 days' \
         WHERE u.classroom_code = $1 \
         GROUP BY u.id \
         ORDER BY weekly_stars DESC \
         LIMIT 10",
    )
    .bind(&code)
    .fetch_all(&state.db)
    .await;

    match rows {
        Ok(data) => shared::ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in get_leaderboard: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn update_grade(
    State(state): State<AppState>,
    Json(body): Json<crate::models::UpdateGradeRequest>,
) -> shared::ApiResponse<serde_json::Value> {
    let result = sqlx::query("UPDATE users SET grade = $1")
        .bind(body.grade)
        .execute(&state.db)
        .await;

    match result {
        Ok(_) => shared::ApiResponse::ok(serde_json::json!({"grade": body.grade})),
        Err(e) => {
            tracing::error!("Database error in update_grade: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}
