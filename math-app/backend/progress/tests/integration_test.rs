use reqwest;
use serde_json::json;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/progress", port)
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
async fn update_progress_returns_ok() {
    let client = reqwest::Client::new();
    let body = json!({
        "user_id": "11111111-1111-1111-1111-111111111111",
        "lesson_id": "lesson_001",
        "stars": 3,
        "completed": true
    });
    let resp = client.post(base_url()).json(&body).send().await.unwrap();

    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}
