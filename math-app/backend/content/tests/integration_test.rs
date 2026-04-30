use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/content", port)
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
async fn curriculum_returns_data() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/curriculum", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 200);
    let json: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(json["success"].as_bool(), Some(true));
    let empty: Vec<serde_json::Value> = vec![];
    let data = json["data"].as_array().unwrap_or(&empty);
    assert!(data.len() > 0);
}

#[tokio::test]
#[ignore]
async fn subjects_returns_three_items() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/subjects", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 200);
    let json: serde_json::Value = resp.json().await.unwrap();
    let empty: Vec<serde_json::Value> = vec![];
    let data = json["data"].as_array().unwrap_or(&empty);
    assert_eq!(data.len(), 3);
}
