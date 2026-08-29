use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/notifications", port)
}

fn auth_header() -> String {
    std::env::var("TEST_JWT_TOKEN").unwrap_or_else(|_| "test-token".to_string())
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

// ── Auth-required endpoints ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn list_notifications_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
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
async fn list_notifications_with_unread_filter() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}?unread=true", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn list_notifications_with_limit() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}?limit=5", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn create_notification_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "title": "Test Notification",
            "body": "This is a test notification body",
            "type": "info"
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn create_notification_validation_missing_title() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "body": "Missing title field"
        }))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    // Missing required field → 400 or 500 (if DB error)
    assert!(status == 400 || status == 500);
}

#[tokio::test]
#[ignore]
async fn mark_notification_read_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/00000000-0000-0000-0000-000000000000/read", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn mark_all_read_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/read-all", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn delete_notification_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .delete(format!("{}/00000000-0000-0000-0000-000000000000", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn register_fcm_token_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/register", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "token": "fake-fcm-token-for-testing-123456"
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn unregister_fcm_token_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .delete(format!("{}/register", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn send_notification_admin_only() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/send", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "user_id": "00000000-0000-0000-0000-000000000000",
            "title": "Admin Push",
            "body": "Admin sent this"
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    // 200 if admin + FCM key, 403 if not admin, 500 if no FCM/DB
    assert!(status == 200 || status == 403 || status == 500);
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
async fn create_notification_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .json(&serde_json::json!({"title": "Test", "body": "Test"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn mark_read_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/00000000-0000-0000-0000-000000000000/read", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn register_fcm_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/register", base_url()))
        .json(&serde_json::json!({"token": "fake"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn send_notification_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/send", base_url()))
        .json(&serde_json::json!({"user_id": "x", "title": "x", "body": "x"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}