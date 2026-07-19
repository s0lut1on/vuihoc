use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct UserExerciseStat {
    pub id: uuid::Uuid,
    pub user_id: uuid::Uuid,
    pub exercise_id: String,
    pub lesson_id: String,
    pub correct_count: i32,
    pub wrong_count: i32,
    pub last_seen_at: DateTime<Utc>,
    pub next_review_at: DateTime<Utc>,
    pub interval_days: i32,
    pub ease_factor: f32,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct ReviewSessionRequest {
    pub user_id: String,
    pub subject_id: Option<String>,
}

#[derive(Serialize, ToSchema)]
pub struct ReviewExercise {
    pub exercise_id: String,
    pub lesson_id: String,
    pub question_vi: String,
    pub question_en: String,
    pub exercise_type: String,
    pub options: Vec<String>,
    pub correct: i32,
    pub wrong_count: i32,
}

#[derive(Serialize, ToSchema)]
pub struct ReviewSession {
    pub exercises: Vec<ReviewExercise>,
    pub due_count: i32,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct Progress {
    pub user_id: uuid::Uuid,
    pub lesson_id: String,
    pub completed: bool,
    pub stars: i32,
    pub attempts: i32,
    pub updated_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct ProgressUpdate {
    pub user_id: String,
    pub lesson_id: String,
    pub stars: i32,
    pub completed: bool,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct Streak {
    pub user_id: uuid::Uuid,
    pub current_streak: i32,
    pub best_streak: i32,
    pub last_activity: DateTime<Utc>,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct DailyLessonCount {
    pub user_id: uuid::Uuid,
    pub lesson_date: chrono::NaiveDate,
    pub count: i32,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct DailyLimitStatus {
    pub count: i32,
    pub has_reached_limit: bool,
    pub limit: i32,
    pub tier: String,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct Achievement {
    pub id: uuid::Uuid,
    pub user_id: uuid::Uuid,
    pub badge_type: String,
    pub earned_at: DateTime<Utc>,
    pub is_new: bool,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct BadgeDefinition {
    pub id: uuid::Uuid,
    pub badge_type: String,
    pub name: String,
    pub description: String,
    pub icon: String,
    pub threshold: i32,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct BatchProgressItem {
    pub lesson_id: String,
    pub stars: i32,
    pub completed: bool,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct BatchProgressRequest {
    pub user_id: String,
    pub items: Vec<BatchProgressItem>,
}

#[derive(Serialize, ToSchema)]
pub struct BatchProgressResponse {
    pub updated: i32,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct AchievementList {
    pub badges: Vec<AchievementWithDefinition>,
}

#[derive(Serialize, Deserialize, sqlx::FromRow, ToSchema, Clone)]
pub struct AchievementWithDefinition {
    pub badge_type: String,
    pub earned_at: Option<DateTime<Utc>>,
    pub is_new: bool,
    pub name: String,
    pub description: String,
    pub icon: String,
    pub threshold: i32,
}

#[derive(Clone)]
pub struct AppState {
    pub db: sqlx::PgPool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn progress_serde_roundtrip() {
        let p = Progress {
            user_id: uuid::Uuid::new_v4(),
            lesson_id: "lesson_001".to_string(),
            completed: true,
            stars: 3,
            attempts: 1,
            updated_at: Utc::now(),
        };
        let json = serde_json::to_string(&p).unwrap();
        assert!(json.contains("lesson_001"));
        assert!(json.contains("true"));
    }

    #[test]
    fn progress_update_serde_roundtrip() {
        let update = ProgressUpdate {
            user_id: uuid::Uuid::new_v4().to_string(),
            lesson_id: "lesson_002".into(),
            stars: 2,
            completed: false,
        };
        let json = serde_json::to_string(&update).unwrap();
        let decoded: ProgressUpdate = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.lesson_id, "lesson_002");
        assert_eq!(decoded.stars, 2);
        assert_eq!(decoded.completed, false);
    }

    #[test]
    fn streak_serde_roundtrip() {
        let s = Streak {
            user_id: uuid::Uuid::new_v4(),
            current_streak: 5,
            best_streak: 10,
            last_activity: Utc::now(),
        };
        let json = serde_json::to_string(&s).unwrap();
        assert!(json.contains("5"));
        assert!(json.contains("10"));
    }

    #[test]
    fn daily_lesson_count_serde_roundtrip() {
        let d = DailyLessonCount {
            user_id: uuid::Uuid::new_v4(),
            lesson_date: chrono::NaiveDate::from_ymd_opt(2024, 1, 15).unwrap(),
            count: 7,
        };
        let json = serde_json::to_string(&d).unwrap();
        assert!(json.contains("7"));
    }

    #[test]
    fn daily_limit_status_serde_roundtrip() {
        let status = DailyLimitStatus {
            count: 5,
            has_reached_limit: false,
            limit: 50,
            tier: "free".to_string(),
        };
        let json = serde_json::to_string(&status).unwrap();
        let decoded: DailyLimitStatus = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.count, 5);
        assert_eq!(decoded.has_reached_limit, false);
        assert_eq!(decoded.limit, 50);
        assert_eq!(decoded.tier, "free");
    }

    #[test]
    fn app_state_clone() {
        fn assert_clone<T: Clone>() {}
        assert_clone::<AppState>();
    }
}
