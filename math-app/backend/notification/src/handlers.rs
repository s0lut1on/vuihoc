use crate::models::{AppState, Notification, NotificationPayload};
use axum::{extract::State, Json};
use shared::{health as shared_health, ApiResponse};
use uuid::Uuid;

pub async fn list_notifications(State(state): State<AppState>) -> ApiResponse<Vec<Notification>> {
    let rows = sqlx::query_as::<_, Notification>(
        "SELECT * FROM notifications ORDER BY created_at DESC LIMIT 20",
    )
    .fetch_all(&state.db)
    .await
    .unwrap_or_default();
    ApiResponse::ok(rows)
}

pub async fn send_test_notification(
    State(state): State<AppState>,
    Json(body): Json<NotificationPayload>,
) -> ApiResponse<Notification> {
    let id = Uuid::new_v4();
    let result = sqlx::query_as::<_, Notification>(
        "INSERT INTO notifications (id, user_id, title_vi, title_en, body_vi, body_en) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
    )
    .bind(id)
    .bind(Uuid::try_parse(&body.user_id).unwrap_or_else(|_| Uuid::new_v4()))
    .bind(&body.title_vi)
    .bind(&body.title_en)
    .bind(&body.body_vi)
    .bind(&body.body_en)
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(n) => ApiResponse::ok(n),
        Err(_) => ApiResponse::err("Failed to send notification"),
    }
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared_health("notification"))
}
