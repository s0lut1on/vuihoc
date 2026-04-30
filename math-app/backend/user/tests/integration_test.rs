use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/users", port)
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
async fn get_user_returns_data() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/test-id", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 200);
}
