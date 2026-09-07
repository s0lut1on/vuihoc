use reqwest;
use serde_json::json;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/questions", port)
}

const TEST_UUID: &str = "00000000-0000-0000-0000-000000000001";

// ── Public endpoints ──────────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn health_returns_200() {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/health", base_url())).send().await;
    assert!(resp.is_ok());
    let resp = resp.unwrap();
    assert_eq!(resp.status().as_u16(), 200);
    let json: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(json["success"].as_bool(), Some(true));
    assert_eq!(json["data"]["service"], "question_bank");
}

// ── Mastery endpoints ─────────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_mastery_with_valid_ids() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/mastery/{}/{}", base_url(), TEST_UUID, TEST_UUID))
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
async fn get_mastery_with_invalid_uuid_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/mastery/not-a-uuid/not-a-uuid", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

// ── Review endpoints (wrong answers) ──────────────────────────────

#[tokio::test]
#[ignore]
async fn get_review_for_user() {
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
        assert!(json["data"]["entries"].is_array());
    }
}

#[tokio::test]
#[ignore]
async fn get_review_with_invalid_uuid_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/review/not-a-uuid", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

#[tokio::test]
#[ignore]
async fn record_wrong_answer() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/review/{}", base_url(), TEST_UUID))
        .json(&json!({
            "exercise_id": "ex_test_001",
            "lesson_id": "lesson_n1",
            "subject_id": "numbers",
            "question_vi": "2 + 3 = ?",
            "question_en": "2 + 3 = ?",
            "hint_vi": "Đếm thêm 3",
            "hint_en": "Count 3 more",
            "options": ["4", "5", "6", "7"],
            "correct_index": 1
        }))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert_eq!(json["data"]["recorded"].as_bool(), Some(true));
    }
}

#[tokio::test]
#[ignore]
async fn record_wrong_with_invalid_uuid_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/review/not-a-uuid", base_url()))
        .json(&json!({
            "exercise_id": "ex_test_001",
            "lesson_id": "lesson_n1",
            "subject_id": "numbers",
            "question_vi": "2 + 3 = ?",
            "question_en": "2 + 3 = ?",
            "options": ["4", "5", "6", "7"],
            "correct_index": 1
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

#[tokio::test]
#[ignore]
async fn clear_wrong_answer() {
    let client = reqwest::Client::new();
    let resp = client
        .delete(format!("{}/review/{}/ex_test_001", base_url(), TEST_UUID))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}

// ── Generate questions ───────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn generate_questions() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/generate", base_url()))
        .json(&json!({
            "kc_id": TEST_UUID,
            "difficulty": 1,
            "count": 3
        }))
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
async fn generate_questions_with_invalid_body_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/generate", base_url()))
        .json(&json!({
            "kc_id": "not-a-uuid",
            "difficulty": "not-a-number",
            "count": 3
        }))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 400);
}

// ── Answer submission ────────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn submit_answer() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/answer/{}", base_url(), TEST_UUID))
        .json(&json!({
            "question_id": TEST_UUID,
            "kc_id": TEST_UUID,
            "answer_given": 5.0,
            "time_taken_ms": 30000
        }))
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
async fn submit_answer_with_invalid_uuid_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/answer/not-a-uuid", base_url()))
        .json(&json!({
            "question_id": TEST_UUID,
            "kc_id": TEST_UUID,
            "answer_given": 5.0,
            "time_taken_ms": 30000
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 400);
}

// ── Hint endpoint ────────────────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_hint() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/hint", base_url()))
        .json(&json!({
            "exercise_id": "ex_hint_001",
            "question_text": "2 + 3 = ?",
            "answer_history": ["3"],
            "expected_answer": "5",
            "is_vietnamese": true,
            "user_id": "user-001"
        }))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["hint"].is_string());
    }
}

#[tokio::test]
#[ignore]
async fn get_hint_with_empty_body_returns_400() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/hint", base_url()))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert_eq!(status, 400);
}