use crate::models::{ReportData, SubjectProgress};
use chrono::{Duration, Utc};
use serde::Deserialize;
use sqlx::PgPool;
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Clone, Copy, Debug)]
pub enum ReportPeriod {
    Daily,
    Weekly,
}

#[derive(Deserialize)]
struct ProgressRow {
    user_id: String,
    lesson_id: String,
    completed: bool,
    stars: i32,
    attempts: i32,
    updated_at: String,
}

#[derive(Deserialize)]
struct StreakData {
    current_streak: i32,
    best_streak: i32,
}

#[derive(Deserialize)]
struct ScoreData {
    total_score: i32,
    correct_count: i32,
    name: String,
}

#[derive(Deserialize)]
struct AchievementRow {
    badge_name: String,
    earned_at: String,
}

/// Known subject IDs in the content DB.
const KNOWN_SUBJECTS: &[&str] = &[
    "numbers",
    "geometry",
    "measurement",
    "logic",
    "algebra",
    "trigonometry",
    "statistics",
    "vietnamese",
    "english",
];

fn subject_info(subject_id: &str) -> (&'static str, &'static str, &'static str) {
    match subject_id {
        "numbers" => ("Toán", "Math", "🔢"),
        "geometry" => ("Hình học", "Geometry", "📐"),
        "measurement" => ("Đo lường", "Measurement", "📏"),
        "logic" => ("Logic", "Logic", "🧩"),
        "algebra" => ("Đại số", "Algebra", "🅰️"),
        "trigonometry" => ("Lượng giác", "Trigonometry", "📐"),
        "statistics" => ("Thống kê", "Statistics", "📊"),
        "vietnamese" => ("Tiếng Việt", "Vietnamese", "🇻🇳"),
        "english" => ("Tiếng Anh", "English", "🇬🇧"),
        _ => ("Khác", "Other", "📚"),
    }
}

/// Extract subject_id from lesson_id.
/// Tries matching known subject IDs as prefix, then falls back to first segment before `_`.
fn extract_subject_id(lesson_id: &str) -> String {
    // Check if lesson_id starts with a known subject ID
    for sid in KNOWN_SUBJECTS {
        if lesson_id.starts_with(sid) {
            // Ensure boundary: next char is _ or end
            let rest = &lesson_id[sid.len()..];
            if rest.is_empty() || rest.starts_with('_') || rest.starts_with('-') {
                return sid.to_string();
            }
        }
    }
    // Fallback: prefix before first _ or -
    lesson_id
        .split(|c| c == '_' || c == '-')
        .next()
        .unwrap_or("other")
        .to_string()
}

fn build_client() -> reqwest::Client {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(5))
        .build()
        .unwrap_or_else(|_| reqwest::Client::new())
}

pub async fn fetch_report_data(
    db: &PgPool,
    user_id: Uuid,
    period: ReportPeriod,
) -> Result<ReportData, String> {
    let locale = sqlx::query_scalar::<_, String>(
        "SELECT timezone FROM notification_preferences WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(db)
    .await
    .ok()
    .flatten()
    .unwrap_or_else(|| "Asia/Ho_Chi_Minh".to_string());

    let locale_str = if locale.contains("America") || locale.contains("Europe") {
        "en"
    } else {
        "vi"
    };

    // 2. Determine period bounds
    let now = Utc::now();
    let period_start = match period {
        ReportPeriod::Daily => now.date_naive().and_hms_opt(0, 0, 0).unwrap(),
        ReportPeriod::Weekly => (now - Duration::days(7)).date_naive().and_hms_opt(0, 0, 0).unwrap(),
    };
    let period_start_str = period_start.format("%Y-%m-%dT%H:%M:%S").to_string();

    // 3. Set period_label
    let period_label = match (&period, locale_str) {
        (ReportPeriod::Daily, "vi") => "hôm nay".to_string(),
        (ReportPeriod::Daily, _) => "today".to_string(),
        (ReportPeriod::Weekly, "vi") => "tuần này".to_string(),
        (ReportPeriod::Weekly, _) => "this week".to_string(),
    };

    let client = build_client();
    let base = "http://progress-service:3000";
    let uid = user_id.to_string();

    let progress_rows: Vec<ProgressRow> = match client
        .get(format!("{}/api/progress/{}", base, uid))
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => resp.json().await.unwrap_or_default(),
        _ => vec![],
    };

    // Fetch streak
    let streak_data: StreakData = match client
        .get(format!("{}/api/progress/streak/{}", base, uid))
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => resp.json().await.unwrap_or(StreakData {
            current_streak: 0,
            best_streak: 0,
        }),
        _ => StreakData {
            current_streak: 0,
            best_streak: 0,
        },
    };

    // Fetch score + name
    let score_data: ScoreData = match client
        .get(format!("{}/api/progress/score/{}", base, uid))
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => resp.json().await.unwrap_or(ScoreData {
            total_score: 0,
            correct_count: 0,
            name: "".to_string(),
        }),
        _ => ScoreData {
            total_score: 0,
            correct_count: 0,
            name: "".to_string(),
        },
    };

    // Fetch achievements
    let achievements: Vec<AchievementRow> = match client
        .get(format!("{}/api/progress/achievements/{}", base, uid))
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => resp.json().await.unwrap_or_default(),
        _ => vec![],
    };

    // 5. Filter progress rows by period
    let period_progress: Vec<&ProgressRow> = progress_rows
        .iter()
        .filter(|p| {
            // Parse updated_at and check >= period_start
            chrono::DateTime::parse_from_rfc3339(&p.updated_at)
                .ok()
                .map(|dt| dt.with_timezone(&Utc) >= chrono::DateTime::<Utc>::from_naive_utc_and_offset(period_start, Utc))
                .unwrap_or(false)
        })
        .collect();

    // 6. Count completed in period
    let lessons_completed_period = period_progress.iter().filter(|p| p.completed).count() as i32;

    // 7. Count total completed
    let lessons_completed_total = progress_rows.iter().filter(|p| p.completed).count() as i32;

    // 8. Sum stars in period
    let total_stars: i32 = period_progress.iter().map(|p| p.stars).sum();

    // 9. Group by subject
    let mut subject_map: HashMap<String, (i32, i32)> = HashMap::new(); // (completed, stars)
    for p in &period_progress {
        if !p.completed {
            continue;
        }
        let sid = extract_subject_id(&p.lesson_id);
        let entry = subject_map.entry(sid).or_insert((0, 0));
        entry.0 += 1;
        entry.1 += p.stars;
    }

    // 10. Build SubjectProgress vec
    let subjects: Vec<SubjectProgress> = subject_map
        .iter()
        .map(|(sid, (completed, stars))| {
            let (name_vi, name_en, icon) = subject_info(sid);
            // completion_pct: relative to total lessons completed in period
            let pct = if lessons_completed_period > 0 {
                (*completed as f64 / lessons_completed_period as f64) * 100.0
            } else {
                0.0
            };
            SubjectProgress {
                subject_id: sid.clone(),
                name_vi: name_vi.to_string(),
                name_en: name_en.to_string(),
                icon: icon.to_string(),
                completed: *completed,
                stars: *stars,
                completion_pct: pct,
            }
        })
        .collect();

    // 11. Filter achievements within period
    let new_achievements: Vec<String> = achievements
        .iter()
        .filter(|a| {
            chrono::DateTime::parse_from_rfc3339(&a.earned_at)
                .ok()
                .map(|dt| dt.with_timezone(&Utc) >= chrono::DateTime::<Utc>::from_naive_utc_and_offset(period_start, Utc))
                .unwrap_or(false)
        })
        .map(|a| a.badge_name.clone())
        .collect();

    // 12. Fetch user name from user service as fallback
    let user_name = if score_data.name.is_empty() {
        match client
            .get(format!("http://user-service:3000/api/users/{}", uid))
            .send()
            .await
        {
            Ok(resp) if resp.status().is_success() => {
                let user_json: serde_json::Value = resp.json().await.unwrap_or_default();
                user_json
                    .get("name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("Bé")
                    .to_string()
            }
            _ => "Bé".to_string(),
        }
    } else {
        score_data.name
    };

    Ok(ReportData {
        user_id,
        user_name,
        locale: locale_str.to_string(),
        period_label,
        lessons_completed_period,
        lessons_completed_total,
        total_stars,
        current_streak: streak_data.current_streak,
        best_streak: streak_data.best_streak,
        total_score: score_data.total_score,
        correct_count: score_data.correct_count,
        new_achievements,
        subjects,
    })
}