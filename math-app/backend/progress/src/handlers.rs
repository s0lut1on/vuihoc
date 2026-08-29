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

pub async fn batch_update_progress(
    State(state): State<AppState>,
    Json(body): Json<BatchProgressRequest>,
) -> ApiResponse<BatchProgressResponse> {
    let user_uuid = match parse_uuid(&body.user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let mut updated = 0i32;
    for item in body.items {
        let result = sqlx::query_as::<_, Progress>(
            "INSERT INTO progress (user_id, lesson_id, completed, stars, attempts, updated_at)
             VALUES ($1, $2, $3, $4, 1, NOW())
             ON CONFLICT (user_id, lesson_id)
             DO UPDATE SET completed = $3, stars = GREATEST(progress.stars, $4), attempts = progress.attempts + 1, updated_at = NOW()
             RETURNING *",
        )
        .bind(user_uuid)
        .bind(&item.lesson_id)
        .bind(item.completed)
        .bind(item.stars)
        .fetch_one(&state.db)
        .await;

        if result.is_ok() {
            updated += 1;
        }
    }

    ApiResponse::ok(BatchProgressResponse { updated })
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

pub async fn update_exercise_stat(
    State(state): State<AppState>,
    Json(body): Json<serde_json::Value>,
) -> ApiResponse<serde_json::Value> {
    let user_id_str = body.get("user_id").and_then(|v| v.as_str()).unwrap_or("");
    let user_uuid = match parse_uuid(user_id_str) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };
    let exercise_id = body
        .get("exercise_id")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let lesson_id = body
        .get("lesson_id")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let is_correct = body
        .get("is_correct")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);

    let existing = sqlx::query_as::<_, UserExerciseStat>(
        "SELECT * FROM user_exercise_stats WHERE user_id = $1 AND exercise_id = $2",
    )
    .bind(user_uuid)
    .bind(&exercise_id)
    .fetch_optional(&state.db)
    .await;

    let now = chrono::Utc::now();
    let next_review = if is_correct {
        let new_interval = match existing {
            Ok(Some(ref stat)) => crate::spaced_repetition::compute_new_interval_days(
                stat.interval_days,
                true,
                stat.correct_count + 1,
            ),
            _ => 1,
        };
        now + chrono::Duration::days(new_interval as i64)
    } else {
        now + chrono::Duration::days(1)
    };

    let result = sqlx::query(
        "INSERT INTO user_exercise_stats (user_id, exercise_id, lesson_id, correct_count, wrong_count, last_seen_at, next_review_at, interval_days, ease_factor) \
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) \
         ON CONFLICT (user_id, exercise_id) \
         DO UPDATE SET \
           correct_count = user_exercise_stats.correct_count + $4, \
           wrong_count = user_exercise_stats.wrong_count + $5, \
           last_seen_at = $6, \
           next_review_at = $7, \
           interval_days = $8, \
           ease_factor = $9 \
         RETURNING *",
    )
    .bind(user_uuid)
    .bind(&exercise_id)
    .bind(&lesson_id)
    .bind(if is_correct { 1 } else { 0 })
    .bind(if is_correct { 0 } else { 1 })
    .bind(now)
    .bind(next_review)
    .bind(if is_correct { crate::spaced_repetition::compute_new_interval_days(1, true, 1) } else { 1 }) // simplified interval reset on wrong
    .bind(2.5f32)
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok(serde_json::json!({ "updated": true })),
        Err(e) => {
            tracing::error!("Database error in update_exercise_stat: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_review_session(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<ReviewSession> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let now = chrono::Utc::now();
    let rows = sqlx::query_as::<_, UserExerciseStat>(
        "SELECT * FROM user_exercise_stats WHERE user_id = $1 AND next_review_at <= $2 AND wrong_count >= 1 ORDER BY next_review_at ASC LIMIT 10"
    )
    .bind(user_uuid)
    .bind(now)
    .fetch_all(&state.db)
    .await;

    match rows {
        Ok(stats) => {
            let exercises: Vec<ReviewExercise> = stats
                .into_iter()
                .map(|stat| ReviewExercise {
                    exercise_id: stat.exercise_id.clone(),
                    lesson_id: stat.lesson_id.clone(),
                    question_vi: String::new(), // populated by frontend or joined query
                    question_en: String::new(),
                    exercise_type: "mcq".to_string(),
                    options: vec![],
                    correct: 0,
                    wrong_count: stat.wrong_count,
                })
                .collect();
            let due_count = exercises.len() as i32;
            ApiResponse::ok(ReviewSession {
                exercises,
                due_count,
            })
        }
        Err(e) => {
            tracing::error!("Database error in get_review_session: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn upsert_subject_score(
    State(state): State<AppState>,
    Json(body): Json<SubjectScoreUpdate>,
) -> ApiResponse<UserScore> {
    let user_uuid = match parse_uuid(&body.user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };

    let result = sqlx::query_as::<_, UserScore>(
        "INSERT INTO user_scores (user_id, total_score, correct_count, total_time_ms, lessons_completed, name, avatar, updated_at)
         VALUES ($1, $2, $3, $4, 1, $5, $6, NOW())
         ON CONFLICT (user_id)
         DO UPDATE SET
           total_score = user_scores.total_score + $2,
           correct_count = user_scores.correct_count + $3,
           total_time_ms = user_scores.total_time_ms + $4,
           lessons_completed = user_scores.lessons_completed + 1,
           name = $5,
           avatar = $6,
           updated_at = NOW()
         RETURNING *",
    )
    .bind(user_uuid)
    .bind(body.score)
    .bind(body.correct_count)
    .bind(body.total_time_ms)
    .bind(&body.name)
    .bind(&body.avatar)
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(row) => ApiResponse::ok(row),
        Err(e) => {
            tracing::error!("Database error in upsert_subject_score: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_user_score(
    State(state): State<AppState>,
    Path(user_id): Path<String>,
) -> ApiResponse<UserScore> {
    let user_uuid = match parse_uuid(&user_id) {
        Ok(u) => u,
        Err(e) => return ApiResponse::err(e),
    };
    let result = sqlx::query_as::<_, UserScore>(
        "SELECT * FROM user_scores WHERE user_id = $1",
    )
    .bind(user_uuid)
    .fetch_optional(&state.db)
    .await;

    match result {
        Ok(Some(row)) => ApiResponse::ok(row),
        Ok(None) => ApiResponse::ok(UserScore {
            user_id: user_uuid,
            total_score: 0,
            correct_count: 0,
            total_time_ms: 0,
            lessons_completed: 0,
            name: String::new(),
            avatar: String::new(),
            updated_at: chrono::Utc::now(),
        }),
        Err(e) => {
            tracing::error!("Database error in get_user_score: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
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
