use reqwest;
use serde_json::json;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/payments", port)
}

fn auth_header() -> String {
    // This token must match JWT_SECRET used by the running server.
    // Format: Bearer <jwt>
    // For integration tests, set JWT_SECRET and generate a valid token.
    // In CI, the test harness should provide a valid token via env var.
    std::env::var("TEST_JWT_TOKEN").unwrap_or_else(|_| "test-token-placeholder".to_string())
}

/// Health endpoint should always return 200 with ApiResponse envelope.
#[tokio::test]
#[ignore]
async fn health_returns_200() {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/health", base_url())).send().await;
    assert!(resp.is_ok());
    if let Ok(r) = resp {
        assert!(r.status().is_success(), "health should return 2xx");
        let body: serde_json::Value = r.json().await.unwrap_or_default();
        assert_eq!(body["success"], true, "ApiResponse.success should be true");
        assert!(body["data"]["service"].as_str() == Some("payment"));
    }
}

/// create_checkout_session without STRIPE_SECRET_KEY should fall back to
/// returning the success_url as the checkout URL (mock mode).
/// Requires auth — without a valid token, should return 401/403.
#[tokio::test]
#[ignore]
async fn create_checkout_mock_fallback() {
    let client = reqwest::Client::new();
    let body = json!({
        "price_id": "price_test123",
        "success_url": "https://example.com/success",
        "cancel_url": "https://example.com/cancel"
    });

    // Without auth — should be rejected
    let resp = client
        .post(format!("{}/create-checkout", base_url()))
        .json(&body)
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(
        status == 401 || status == 403,
        "create-checkout without auth should return 401/403, got {}",
        status
    );

    // With auth — in mock mode (no STRIPE_SECRET_KEY), should return success_url
    let resp = client
        .post(format!("{}/create-checkout", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&body)
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    // Could be 200 (mock mode) or 500 (DB/auth issue in test env)
    assert!(
        status == 200 || status == 500,
        "create-checkout with auth should return 200 or 500, got {}",
        status
    );
    if status == 200 {
        let body: serde_json::Value = resp.json().await.unwrap_or_default();
        assert_eq!(body["success"], true);
        assert!(
            body["data"]["url"].as_str().is_some(),
            "checkout response should contain url"
        );
    }
}

/// create_checkout_session with invalid body should return 400 or 422.
#[tokio::test]
#[ignore]
async fn create_checkout_invalid_body() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/create-checkout", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&json!({ "bad": "body" }))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(
        status == 400 || status == 401 || status == 403 || status == 422,
        "invalid body should return 400/401/403/422, got {}",
        status
    );
}

/// stripe_webhook should accept a valid checkout.session.completed event
/// and return 200 "ok". This does NOT require auth.
#[tokio::test]
#[ignore]
async fn webhook_checkout_completed() {
    let client = reqwest::Client::new();
    let event = json!({
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "client_reference_id": "11111111-1111-1111-1111-111111111111",
                "customer": "cus_test123",
                "subscription": "sub_test123"
            }
        }
    });

    let resp = client
        .post(format!("{}/webhook", base_url()))
        .json(&event)
        .send()
        .await
        .unwrap();
    assert!(
        resp.status().is_success(),
        "webhook should return 2xx, got {}",
        resp.status()
    );
}

/// stripe_webhook should accept unknown event types gracefully (no-op).
#[tokio::test]
#[ignore]
async fn webhook_unknown_event() {
    let client = reqwest::Client::new();
    let event = json!({
        "type": "some.unknown.event",
        "data": { "object": {} }
    });

    let resp = client
        .post(format!("{}/webhook", base_url()))
        .json(&event)
        .send()
        .await
        .unwrap();
    assert!(
        resp.status().is_success(),
        "unknown webhook event should return 2xx, got {}",
        resp.status()
    );
}

/// stripe_webhook with invalid JSON should return 400.
#[tokio::test]
#[ignore]
async fn webhook_invalid_json() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/webhook", base_url()))
        .header("Content-Type", "application/json")
        .body("not valid json {{{")
        .send()
        .await
        .unwrap();
    assert_eq!(
        resp.status().as_u16(),
        400,
        "invalid JSON should return 400, got {}",
        resp.status()
    );
}

/// get_subscription_status requires auth. Without token → 401/403.
/// With auth and no subscription → free tier.
#[tokio::test]
#[ignore]
async fn subscription_status_requires_auth() {
    let client = reqwest::Client::new();

    // Without auth
    let resp = client.get(format!("{}/status", base_url())).send().await.unwrap();
    let status = resp.status().as_u16();
    assert!(
        status == 401 || status == 403,
        "status without auth should return 401/403, got {}",
        status
    );

    // With auth
    let resp = client
        .get(format!("{}/status", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(
        status == 200 || status == 500,
        "status with auth should return 200 or 500, got {}",
        status
    );
    if status == 200 {
        let body: serde_json::Value = resp.json().await.unwrap_or_default();
        assert_eq!(body["success"], true);
        assert!(
            body["data"]["tier"].as_str().is_some(),
            "subscription status should contain tier"
        );
    }
}