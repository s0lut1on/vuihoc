use axum::{
    extract::{Path, State},
    Extension, Json,
};

use crate::models::{AppState, CreateUserRequest, User};

pub async fn list_children(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
) -> shared::ApiResponse<Vec<User>> {
    let parent_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };
    let children = sqlx::query_as::<_, User>("SELECT * FROM users WHERE parent_id = $1")
        .bind(parent_id)
        .fetch_all(&state.db)
        .await;
    match children {
        Ok(data) => shared::ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in list_children: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}

pub async fn create_child(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
    Json(body): Json<crate::models::CreateChildRequest>,
) -> shared::ApiResponse<User> {
    let parent_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };
    let grade = body.grade.unwrap_or(1);
    let child = sqlx::query_as::<_, User>(
        "INSERT INTO users (name, persona, avatar, grade, parent_id) VALUES ($1, $2, $3, $4, $5) RETURNING *",
    )
    .bind(&body.name)
    .bind("achiever")
    .bind("🐸")
    .bind(grade)
    .bind(parent_id)
    .fetch_one(&state.db)
    .await;
    match child {
        Ok(u) => shared::ApiResponse::ok(u),
        Err(e) => {
            tracing::error!("Database error in create_child: {}", e);
            shared::ApiResponse::err("Failed to create child")
        }
    }
}

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
            tracing::info!(
                "User not found, auto-creating default user for id={}",
                user_id
            );
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



pub async fn update_grade(
    State(state): State<AppState>,
    Extension(claims): Extension<shared::Claims>,
    Json(body): Json<crate::models::UpdateGradeRequest>,
) -> shared::ApiResponse<serde_json::Value> {
    if !(1..=12).contains(&body.grade) {
        return shared::ApiResponse::err("grade must be 1..=12");
    }
    let user_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };
    let result = sqlx::query("UPDATE users SET grade = $1 WHERE id = $2")
        .bind(body.grade)
        .bind(user_id)
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

pub async fn get_global_leaderboard(
    State(state): State<AppState>,
) -> shared::ApiResponse<Vec<crate::models::GlobalLeaderboardEntry>> {
    let rows = sqlx::query_as::<_, crate::models::GlobalLeaderboardEntry>(
        "SELECT s.user_id as id, s.name, s.avatar, \
         s.total_score, s.lessons_completed \
         FROM user_scores s \
         WHERE s.total_score > 0 \
         ORDER BY s.total_score DESC \
         LIMIT 50",
    )
    .fetch_all(&state.db)
    .await;

    match rows {
        Ok(data) => shared::ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in get_global_leaderboard: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}


