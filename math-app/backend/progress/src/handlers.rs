use crate::models::*;
use axum::extract::{Path, State};
use axum::Json;
use shared::ApiResponse;

pub async fn get_user_progress(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<Vec<Progress>> {
    let user_uuid = match uuid::Uuid::try_parse(&user_id) {
        Ok(u) => u,
        Err(_) => return ApiResponse::err("Invalid user_id format"),
    };

    let rows = sqlx::query_as::<_, Progress>("SELECT * FROM progress WHERE user_id = $1")
        .bind(user_uuid)
        .fetch_all(&state.db)
        .await;

    match rows {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => ApiResponse::err(&format!("Failed: {}", e)),
    }
}

pub async fn get_user_streak(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<Streak> {
    let user_uuid = match uuid::Uuid::try_parse(&user_id) {
        Ok(u) => u,
        Err(_) => return ApiResponse::err("Invalid user_id format"),
    };

    let row = sqlx::query_as::<_, Streak>("SELECT * FROM streaks WHERE user_id = $1")
        .bind(user_uuid)
        .fetch_optional(&state.db)
        .await;

    match row {
        Ok(Some(streak)) => ApiResponse::ok(streak),
        Ok(None) => ApiResponse::ok(Streak {
            user_id: user_uuid,
            current_streak: 0,
            best_streak: 0,
            last_activity: chrono::Utc::now(),
        }),
        Err(e) => ApiResponse::err(&format!("Failed: {}", e)),
    }
}

pub async fn update_progress(
    State(state): State<AppState>,
    Json(body): Json<ProgressUpdate>,
) -> ApiResponse<Progress> {
    let user_uuid = match uuid::Uuid::try_parse(&body.user_id) {
        Ok(u) => u,
        Err(_) => return ApiResponse::err("Invalid user_id format"),
    };

    let result = sqlx::query_as::<_, Progress>(
        "INSERT INTO progress (user_id, lesson_id, completed, stars, attempts, updated_at)\n          VALUES ($1, $2, $3, $4, 1, NOW())\n          ON CONFLICT (user_id, lesson_id)\n          DO UPDATE SET completed = $3, stars = GREATEST(progress.stars, $4), attempts = progress.attempts + 1, updated_at = NOW()\n          RETURNING *",
    )
    .bind(user_uuid)
    .bind(&body.lesson_id)
    .bind(body.completed)
    .bind(body.stars)
    .fetch_one(&state.db)
    .await;

    if let Ok(ref progress) = result {
        if progress.completed {
            let _ = update_streak(&state.db, user_uuid).await;
        }
    }

    match result {
        Ok(p) => ApiResponse::ok(p),
        Err(e) => ApiResponse::err(&format!("Failed: {}", e)),
    }
}

async fn update_streak(db: &sqlx::PgPool, user_id: uuid::Uuid) -> Result<(), sqlx::Error> {
    let today = chrono::Utc::now().date_naive();

    let existing = sqlx::query_as::<_, Streak>("SELECT * FROM streaks WHERE user_id = $1")
        .bind(user_id)
        .fetch_optional(db)
        .await?;

    match existing {
        Some(streak) => {
            let last_date = streak.last_activity.date_naive();
            let days_diff = today.signed_duration_since(last_date).num_days();

            let (new_current, new_best) = if days_diff == 0 {
                (streak.current_streak, streak.best_streak)
            } else if days_diff == 1 {
                let new_current = streak.current_streak + 1;
                let new_best = if new_current > streak.best_streak {
                    new_current
                } else {
                    streak.best_streak
                };
                (new_current, new_best)
            } else {
                (1, streak.best_streak)
            };

            sqlx::query(
                "UPDATE streaks SET current_streak = $1, best_streak = $2, last_activity = NOW() WHERE user_id = $3",
            )
            .bind(new_current)
            .bind(new_best)
            .bind(user_id)
            .execute(db)
            .await?;
        }
        None => {
            sqlx::query(
                "INSERT INTO streaks (user_id, current_streak, best_streak, last_activity) VALUES ($1, 1, 1, NOW())",
            )
            .bind(user_id)
            .execute(db)
            .await?;
        }
    }

    Ok(())
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("progress"))
}
