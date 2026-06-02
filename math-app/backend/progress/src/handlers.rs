use crate::models::*;
use axum::extract::{Path, State};
use axum::Json;
use shared::ApiResponse;

pub async fn get_user_progress(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<Vec<Progress>> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let rows = sqlx::query_as::<_, Progress>("SELECT * FROM progress WHERE user_id = $1")
        .bind(user_uuid)
        .fetch_all(&state.db)
        .await;

    match rows {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in get_user_progress: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_user_streak(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<Streak> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
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
        Err(e) => {
            tracing::error!("Database error in get_user_streak: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_daily_limit(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<DailyLimitStatus> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let daily = get_or_create_daily_count(&state.db, user_uuid, &user_id).await;
    match daily {
        Ok(d) => ApiResponse::ok(DailyLimitStatus {
            count: d.count,
            has_reached_limit: d.count >= 50,
            limit: 50,
            tier: String::new(),
        }),
        Err(e) => {
            tracing::error!("Database error in get_daily_limit: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn update_progress(
    State(state): State<AppState>,
    Json(body): Json<ProgressUpdate>,
) -> ApiResponse<Progress> {
    let user_uuid = match parse_uuid(&body.user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let result = sqlx::query_as::<_, Progress>("INSERT INTO progress (user_id, lesson_id, completed, stars, attempts, updated_at)\n          VALUES ($1, $2, $3, $4, 1, NOW())\n          ON CONFLICT (user_id, lesson_id)\n          DO UPDATE SET completed = $3, stars = GREATEST(progress.stars, $4), attempts = progress.attempts + 1, updated_at = NOW()\n          RETURNING *",
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
            let _ = increment_daily_count(&state.db, user_uuid).await;
            let _ = check_and_award_achievements(&state.db, user_uuid).await;
        }
    }

    match result {
        Ok(p) => ApiResponse::ok(p),
        Err(e) => {
            tracing::error!("Database error in update_progress: {}", e);
            ApiResponse::err("Internal server error")
        }
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
            let (new_current, new_best) =
                compute_new_streak(last_date, today, streak.current_streak, streak.best_streak);

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

async fn get_or_create_daily_count(
    db: &sqlx::PgPool,
    user_id: uuid::Uuid,
    _user_id_str: &str,
) -> Result<DailyLessonCount, sqlx::Error> {
    let today = chrono::Utc::now().date_naive();

    let existing = sqlx::query_as::<_, DailyLessonCount>(
        "SELECT user_id, lesson_date, count FROM daily_lessons WHERE user_id = $1 AND lesson_date = $2",
    )
    .bind(user_id)
    .bind(today)
    .fetch_optional(db)
    .await?;

    match existing {
        Some(d) => Ok(d),
        None => {
            sqlx::query(
                "INSERT INTO daily_lessons (user_id, lesson_date, count) VALUES ($1, $2, 0)\n                 ON CONFLICT (user_id, lesson_date) DO NOTHING",
            )
            .bind(user_id)
            .bind(today)
            .execute(db)
            .await?;

            Ok(DailyLessonCount {
                user_id,
                lesson_date: today,
                count: 0,
            })
        }
    }
}

async fn increment_daily_count(db: &sqlx::PgPool, user_id: uuid::Uuid) -> Result<(), sqlx::Error> {
    let today = chrono::Utc::now().date_naive();
    sqlx::query(
        "INSERT INTO daily_lessons (user_id, lesson_date, count) VALUES ($1, $2, 1)\n         ON CONFLICT (user_id, lesson_date) DO UPDATE SET count = daily_lessons.count + 1",
    )
    .bind(user_id)
    .bind(today)
    .execute(db)
    .await?;

    Ok(())
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("progress"))
}

pub async fn get_user_achievements(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<Vec<AchievementWithDefinition>> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let rows = sqlx::query_as::<_, AchievementWithDefinition>(
        "SELECT bd.badge_type, a.earned_at, COALESCE(a.is_new, false) as is_new, bd.name, bd.description, bd.icon, bd.threshold \
         FROM badge_definitions bd \
         LEFT JOIN achievements a ON bd.badge_type = a.badge_type AND a.user_id = $1 \
         ORDER BY bd.threshold ASC"
    )
    .bind(user_uuid)
    .fetch_all(&state.db)
    .await;

    match rows {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in get_user_achievements: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn mark_achievement_read(
    State(state): State<AppState>,
    Path((user_id, badge_type)): Path<(String, String)>,
) -> ApiResponse<String> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let result = sqlx::query(
        "UPDATE achievements SET is_new = false WHERE user_id = $1 AND badge_type = $2",
    )
    .bind(user_uuid)
    .bind(&badge_type)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok("marked".to_string()),
        Err(e) => {
            tracing::error!("Database error in mark_achievement_read: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

async fn check_and_award_achievements(
    db: &sqlx::PgPool,
    user_id: uuid::Uuid,
) -> Result<(), sqlx::Error> {
    let total_stars: i64 = sqlx::query_scalar::<_, i64>(
        "SELECT COALESCE(SUM(stars), 0) FROM progress WHERE user_id = $1 AND completed = true",
    )
    .bind(user_id)
    .fetch_one(db)
    .await?;

    let total_lessons: i64 = sqlx::query_scalar::<_, i64>(
        "SELECT COUNT(*) FROM progress WHERE user_id = $1 AND completed = true",
    )
    .bind(user_id)
    .fetch_one(db)
    .await?;

    let best_streak: i32 = sqlx::query_scalar::<_, i32>(
        "SELECT COALESCE(best_streak, 0) FROM streaks WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(db)
    .await?
    .unwrap_or(0);

    let thresholds: [(String, i32); 6] = [
        ("first_lesson".to_string(), total_lessons as i32),
        ("streak_3".to_string(), best_streak),
        ("streak_7".to_string(), best_streak),
        ("streak_30".to_string(), best_streak),
        ("star_collector_10".to_string(), total_stars as i32),
        ("star_collector_50".to_string(), total_stars as i32),
    ];

    sqlx::query("BEGIN").execute(db).await?;

    for (badge, value) in thresholds.iter() {
        let req: i32 = match badge.as_str() {
            "first_lesson" => 1,
            "streak_3" => 3,
            "streak_7" => 7,
            "streak_30" => 30,
            "star_collector_10" => 10,
            "star_collector_50" => 50,
            _ => continue,
        };

        if *value >= req {
            let _ = sqlx::query(
                "INSERT INTO achievements (user_id, badge_type, earned_at, is_new) \
                 VALUES ($1, $2, NOW(), true) \
                 ON CONFLICT (user_id, badge_type) DO NOTHING",
            )
            .bind(user_id)
            .bind(badge)
            .execute(db)
            .await;
        }
    }

    sqlx::query("COMMIT").execute(db).await?;
    Ok(())
}

fn parse_uuid(user_id: &str) -> Result<uuid::Uuid, &'static str> {
    uuid::Uuid::try_parse(user_id).map_err(|_| "Invalid user_id format")
}

fn compute_new_streak(
    last_date: chrono::NaiveDate,
    today: chrono::NaiveDate,
    current: i32,
    best: i32,
) -> (i32, i32) {
    let days_diff = today.signed_duration_since(last_date).num_days();

    if days_diff == 0 {
        (current, best)
    } else if days_diff == 1 {
        let new_current = current + 1;
        let new_best = if new_current > best {
            new_current
        } else {
            best
        };
        (new_current, new_best)
    } else {
        (1, best)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_uuid_valid() {
        let id = "11111111-1111-1111-1111-111111111111";
        let result = parse_uuid(id);
        assert!(result.is_ok());
    }

    #[test]
    fn parse_uuid_invalid() {
        let result = parse_uuid("not-a-uuid");
        assert!(result.is_err());
    }

    #[test]
    fn parse_uuid_empty() {
        let result = parse_uuid("");
        assert!(result.is_err());
    }

    #[test]
    fn streak_same_day_no_change() {
        let today = chrono::Utc::now().date_naive();
        let (c, b) = compute_new_streak(today, today, 5, 10);
        assert_eq!(c, 5);
        assert_eq!(b, 10);
    }

    #[test]
    fn streak_next_day_increments() {
        let today = chrono::Utc::now().date_naive();
        let yesterday = today.pred_opt().unwrap();
        let (c, b) = compute_new_streak(yesterday, today, 5, 10);
        assert_eq!(c, 6);
        assert_eq!(b, 10);
    }

    #[test]
    fn streak_next_day_updates_best() {
        let today = chrono::Utc::now().date_naive();
        let yesterday = today.pred_opt().unwrap();
        let (c, b) = compute_new_streak(yesterday, today, 10, 10);
        assert_eq!(c, 11);
        assert_eq!(b, 11);
    }

    #[test]
    fn streak_gap_resets() {
        let today = chrono::Utc::now().date_naive();
        let three_days_ago = today - chrono::Duration::days(3);
        let (c, b) = compute_new_streak(three_days_ago, today, 5, 10);
        assert_eq!(c, 1);
        assert_eq!(b, 10);
    }
}
