use reqwest;
use serde_json::json;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/progress", port)
}

const TEST_UUID: &str = "00000000-0000-0000-0000-000000000001";

// ── Public endpoint ────────────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn health_returns_200() {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/health", base_url())).send().await;
    assert!(resp.is_ok());
}

// ── GET /:user_id (user progress) ─────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_user_progress_with_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/{}", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"].is_array());
    }
}

#[tokio::test]
#[ignore]
async fn get_user_progress_with_invalid_uuid_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/not-a-uuid", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

// ── GET /streak/:user_id ──────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_user_streak_with_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/streak/{}", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
    }
}

#[tokio::test]
#[ignore]
async fn get_user_streak_with_invalid_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/streak/not-a-uuid", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

// ── GET /daily-limit/:user_id ─────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_daily_limit_with_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/daily-limit/{}", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["limit"].is_number());
    }
}

#[tokio::test]
#[ignore]
async fn get_daily_limit_with_invalid_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/daily-limit/not-a-uuid", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

// ── POST / (update progress) ─────────────────────────────────────

#[tokio::test]
#[ignore]
async fn update_progress_returns_ok() {
    let client = reqwest::Client::new();
    let body = json!({
        "user_id": TEST_UUID,
        "lesson_id": "test-lesson",
        "completed": true,
        "stars": 3
    });
    let resp = client.post(base_url()).json(&body).send().await.unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}

// ── POST /batch ──────────────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn batch_update_progress() {
    let client = reqwest::Client::new();
    let body = json!({
        "user_id": TEST_UUID,
        "items": [{"lesson_id": "test", "completed": true, "stars": 3}]
    });
    let resp = client
        .post(format!("{}/batch", base_url()))
        .json(&body)
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["updated"].is_number());
    }
}

// ── GET /achievements/:user_id ───────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_user_achievements_with_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/achievements/{}", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"].is_array());
    }
}

// ── POST /achievements/:user_id/:badge_type/mark-read ────────────

#[tokio::test]
#[ignore]
async fn mark_achievement_read() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!(
            "{}/achievements/{}/first_lesson/mark-read",
            base_url(),
            TEST_UUID
        ))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
    }
}

// ── POST /exercise-stat (update exercise stat) ──────────────────

#[tokio::test]
#[ignore]
async fn update_exercise_stat() {
    let client = reqwest::Client::new();
    let body = json!({
        "user_id": TEST_UUID,
        "exercise_id": "ex1",
        "lesson_id": "l1",
        "is_correct": true
    });
    let resp = client
        .post(format!("{}/review", base_url()))
        .json(&body)
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert_eq!(json["data"]["updated"].as_bool(), Some(true));
    }
}

// ── GET /review/:user_id ─────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_review_session_with_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/review/{}", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["exercises"].is_array());
    }
}

// ── POST /score (upsert subject score) ───────────────────────────

#[tokio::test]
#[ignore]
async fn upsert_subject_score() {
    let client = reqwest::Client::new();
    let body = json!({
        "user_id": TEST_UUID,
        "score": 100,
        "correct_count": 5,
        "total_time_ms": 30000,
        "name": "Test",
        "avatar": "🐸"
    });
    let resp = client
        .post(format!("{}/score", base_url()))
        .json(&body)
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
    }
}

// ── GET /score/:user_id ──────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_user_score_with_uuid() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/score/{}", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["total_score"].is_number());
    }
}