use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/media", port)
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
async fn list_media_returns_ok() {
    let client = reqwest::Client::new();
    let resp = client.get(base_url()).send().await.unwrap();
    assert_eq!(resp.status().as_u16(), 200);
}
