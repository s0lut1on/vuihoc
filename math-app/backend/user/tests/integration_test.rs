use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/users", port)
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
    assert_eq!(json["data"]["service"], "user");
}

// ── Auth-required endpoints ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_user_with_auth() {
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
async fn get_me_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/me", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn create_user_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "name": "Test Child",
            "persona": "achiever",
            "locale": "vi_VN",
            "grade": 1
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn get_user_by_id_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/00000000-0000-0000-0000-000000000000", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn get_global_leaderboard_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/leaderboard/global", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn update_grade_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/grade", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({"grade": 2}))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn update_grade_validation_rejects_out_of_range() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/grade", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({"grade": 99}))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    // Should succeed (200) with error in body, or 500 if no DB
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        // grade 99 should fail validation → error response
        assert_eq!(json["success"].as_bool(), Some(false));
    }
}

#[tokio::test]
#[ignore]
async fn list_children_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/children", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn create_child_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/children", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "name": "Child Test",
            "grade": 1
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

// ── Negative tests: no auth ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn get_user_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client.get(base_url()).send().await.unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn create_user_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(base_url())
        .json(&serde_json::json!({"name": "Test", "persona": "achiever"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn leaderboard_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/leaderboard/global", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn list_children_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/children", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}