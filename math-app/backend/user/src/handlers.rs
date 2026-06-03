use axum::{extract::State, Extension, Json};
use chrono::Utc;

use crate::models::{AppState, CreateUserRequest, JoinClassroomRequest, User};

pub async fn get_user(State(state): State<AppState>) -> shared::ApiResponse<User> {
    let user = sqlx::query_as::<_, User>("SELECT * FROM users LIMIT 1")
        .fetch_optional(&state.db)
        .await;
    match user {
        Ok(Some(u)) => shared::ApiResponse::ok(u),
        Ok(None) => shared::ApiResponse::ok(User {
            id: uuid::Uuid::new_v4(),
            email: None,
            name: "Be Minh Anh".to_string(),
            persona: "achiever".to_string(),
            avatar: "🐸".to_string(),
            streak_days: 7,
            gems: 248,
            total_lessons: 12,
            total_stars: 3,
            locale: "vi_VN".to_string(),
            subscription_tier: "free".to_string(),
            classroom_code: None,
            grade: 1,
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
    Extension(claims): Extension<shared::Claims>,
    Json(body): Json<crate::models::UpdateGradeRequest>,
) -> shared::ApiResponse<serde_json::Value> {
    let user_id = match uuid::Uuid::try_parse(&claims.sub) {
        Ok(u) => u,
        Err(_) => return shared::ApiResponse::err("Invalid user_id"),
    };

    let result = sqlx::query("UPDATE users SET grade = $1 WHERE id = $2 RETURNING id")
        .bind(body.grade)
        .bind(user_id)
        .fetch_one(&state.db)
        .await;

    match result {
        Ok(_) => shared::ApiResponse::ok(serde_json::json!({"grade": body.grade})),
        Err(e) => {
            tracing::error!("Database error in update_grade: {}", e);
            shared::ApiResponse::err("Internal server error")
        }
    }
}
