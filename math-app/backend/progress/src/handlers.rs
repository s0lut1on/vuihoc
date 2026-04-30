use crate::models::*;
use axum::{extract::State, Json};
use shared::ApiResponse;

pub async fn get_progress(State(state): State<AppState>) -> ApiResponse<Vec<Progress>> {
    let rows = sqlx::query_as::<_, Progress>("SELECT * FROM progress LIMIT 10")
        .fetch_all(&state.db)
        .await
        .unwrap_or_default();
    ApiResponse::ok(rows)
}

pub async fn update_progress(
    State(state): State<AppState>,
    Json(body): Json<ProgressUpdate>,
) -> ApiResponse<Progress> {
    let result = sqlx::query_as::<_, Progress>(
        "INSERT INTO progress (user_id, lesson_id, completed, stars, attempts, updated_at)\n          VALUES ($1, $2, $3, $4, 1, NOW())\n          ON CONFLICT (user_id, lesson_id)\n          DO UPDATE SET completed = $3, stars = GREATEST(progress.stars, $4), attempts = progress.attempts + 1, updated_at = NOW()\n          RETURNING *",
    )
    .bind(uuid::Uuid::try_parse(&body.user_id).unwrap_or(uuid::Uuid::new_v4()))
    .bind(&body.lesson_id)
    .bind(body.completed)
    .bind(body.stars)
    .fetch_one(&state.db)
    .await;
    match result {
        Ok(p) => ApiResponse::ok(p),
        Err(e) => ApiResponse::err(&format!("Failed: {}", e)),
    }
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("progress"))
}
