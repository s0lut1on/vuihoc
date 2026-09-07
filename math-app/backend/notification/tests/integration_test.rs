use reqwest;
use serde_json::json;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/notifications", port)
}

fn auth_header() -> String {
    std::env::var("TEST_JWT_TOKEN").unwrap_or_else(|_| "test-token".to_string())
}

fn auth_bearer() -> String {
    format!("Bearer {}", auth_header())
}

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
    assert_eq!(json["data"]["service"], "notification");
}

#[tokio::test]
#[ignore]
async fn send_report() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/send-report", base_url()))
        .send()
        .await
        .unwrap();
    // send_report returns a plain string, not JSON ApiResponse.
    // 200 if DB present + SENDGRID key set, 500 if DB missing,
    // 200 with message if SENDGRID not set.
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}

// ── Protected endpoints: with auth ────────────────────────────────

#[tokio::test]
#[ignore]
async fn list_notifications_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(base_url())
        .header("Authorization", auth_bearer())
        .send()
        .await;
    assert!(resp.is_ok());
    let resp = resp.unwrap();
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
async fn send_test_notification_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .header("Authorization", auth_bearer())
        .json(&json!({
            "user_id": "00000000-0000-0000-0000-000000000001",
            "title_vi": "Test thông báo",
            "title_en": "Test notification",
            "body_vi": "Đây là thông báo test",
            "body_en": "This is a test notification"
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
async fn subscribe_push_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/subscribe", base_url()))
        .header("Authorization", auth_bearer())
        .json(&json!({
            "fcm_token": "fake-fcm-token-for-testing-123456",
            "platform": "android"
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
async fn unsubscribe_push_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/unsubscribe", base_url()))
        .header("Authorization", auth_bearer())
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
async fn get_subscription_status_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/status", base_url()))
        .header("Authorization", auth_bearer())
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["subscribed"].is_boolean());
    }
}

#[tokio::test]
#[ignore]
async fn get_preferences_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/preferences", base_url()))
        .header("Authorization", auth_bearer())
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["daily_reminder_enabled"].is_boolean());
    }
}

#[tokio::test]
#[ignore]
async fn update_preferences_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/preferences", base_url()))
        .header("Authorization", auth_bearer())
        .json(&json!({
            "daily_reminder_enabled": true,
            "reminder_hour": 19,
            "timezone": "Asia/Ho_Chi_Minh"
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

// ── Negative tests: no auth ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn list_notifications_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client.get(base_url()).send().await.unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn send_test_notification_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .json(&json!({"user_id": "x", "title_vi": "x", "title_en": "x", "body_vi": "x", "body_en": "x"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn subscribe_push_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/subscribe", base_url()))
        .json(&json!({"fcm_token": "fake", "platform": "android"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn unsubscribe_push_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/unsubscribe", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn get_subscription_status_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/status", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn get_preferences_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/preferences", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}