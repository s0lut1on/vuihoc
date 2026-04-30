use reqwest;
use serde_json::json;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/auth", port)
}

#[tokio::test]
#[ignore]
async fn health_returns_200() {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/health", base_url())).send().await;
    assert!(resp.is_ok());
}

#[tokio::test]
#[ignore]
async fn register_returns_token() {
    let client = reqwest::Client::new();
    let body = json!({"email":"test@example.com","password":"123456","name":"Test"});
    let resp = client
        .post(format!("{}/register", base_url()))
        .json(&body)
        .send()
        .await
        .unwrap();

    assert_eq!(resp.status().as_u16(), 200);
    let json: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(json["success"].as_bool(), Some(true));
    assert!(json["data"]["access_token"].as_str().unwrap_or("").len() > 0);
}

#[tokio::test]
#[ignore]
async fn me_returns_user_profile() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/me", base_url()))
        .send()
        .await
        .unwrap();

    assert_eq!(resp.status().as_u16(), 200);
    let json: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(json["data"]["persona"].as_str(), Some("achiever"));
}

#[tokio::test]
#[ignore]
async fn google_login_with_invalid_token_fails() {
    let client = reqwest::Client::new();
    let body = json!({"id_token":"invalid-token"});
    let resp = client
        .post(format!("{}/google", base_url()))
        .json(&body)
        .send()
        .await
        .unwrap();

    assert_eq!(resp.status().as_u16(), 200);
    let json: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(json["success"].as_bool(), Some(false));
}
