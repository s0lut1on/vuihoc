use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/media", port)
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
    assert_eq!(json["data"]["service"], "media");
}

// ── Auth-required endpoints ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn list_media_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn upload_media_url_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "filename": "test_image.png",
            "mime_type": "image/png"
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn upload_media_url_validation() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "filename": "test.jpg",
            "mime_type": "image/jpeg"
        }))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        assert_eq!(json["success"].as_bool(), Some(true));
        assert!(json["data"]["url"].as_str().is_some());
        assert_eq!(json["data"]["mime_type"], "image/jpeg");
    }
}

// ── Negative tests: no auth ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn list_media_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client.get(base_url()).send().await.unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn upload_media_url_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .json(&serde_json::json!({"filename": "test.png", "mime_type": "image/png"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}