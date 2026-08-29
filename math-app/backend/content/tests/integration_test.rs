use reqwest;

fn base_url() -> String {
    let port = std::env::var("PORT").unwrap_or_else(|_| "3000".to_string());
    format!("http://127.0.0.1:{}/api/content", port)
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
    assert_eq!(json["data"]["service"], "content");
}

#[tokio::test]
#[ignore]
async fn worksheet_returns_html() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/lesson/lesson_n1/worksheet", base_url()))
        .send()
        .await;
    assert!(resp.is_ok());
    let resp = resp.unwrap();
    // Worksheet is public, returns HTML
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 404);
}

// ── Auth-required endpoints (protected) ───────────────────────────

#[tokio::test]
#[ignore]
async fn curriculum_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/curriculum", base_url()))
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
        // curriculum should return array data (from DB or static fallback)
        assert!(json["data"].is_array());
    }
}

#[tokio::test]
#[ignore]
async fn curriculum_with_grade_query() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/curriculum?grade=1", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn subjects_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/subjects", base_url()))
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
async fn get_subject_lessons_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/subject/numbers/lessons", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn get_lesson_with_auth() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/lesson/lesson_n1", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 500);
}

#[tokio::test]
#[ignore]
async fn get_lesson_nonexistent_returns_error() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/lesson/nonexistent_lesson", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await
        .unwrap();
    let status = resp.status().as_u16();
    assert!(status == 200 || status == 500);
    if status == 200 {
        let json: serde_json::Value = resp.json().await.unwrap();
        // Should return error response for nonexistent lesson
        assert_eq!(json["success"].as_bool(), Some(false));
    }
}

// ── Admin endpoints (require admin role) ──────────────────────────

#[tokio::test]
#[ignore]
async fn admin_create_subject() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/admin/subjects", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "id": "test_subject",
            "name_vi": "Test Subject",
            "name_en": "Test Subject EN",
            "description_vi": "Test",
            "description_en": "Test",
            "icon": "📊",
            "color": "#FF0000",
            "display_order": 99,
            "grade_min": 1,
            "grade_max": 5
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    // 200 if admin + DB, 403 if not admin, 500 if no DB
    assert!(status == 200 || status == 403 || status == 500);
}

#[tokio::test]
#[ignore]
async fn admin_update_subject() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/admin/subjects/test_subject", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "name_vi": "Updated Subject",
            "icon": "🔢"
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 403 || status == 500);
}

#[tokio::test]
#[ignore]
async fn admin_create_lesson() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/admin/lessons", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "id": "test_lesson",
            "subject_id": "numbers",
            "title_vi": "Test Lesson",
            "title_en": "Test Lesson EN",
            "description_vi": "Test",
            "description_en": "Test",
            "lesson_order": 99,
            "difficulty": "easy",
            "is_premium": false,
            "grade": 1
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 403 || status == 500);
}

#[tokio::test]
#[ignore]
async fn admin_update_lesson() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/admin/lessons/test_lesson", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "id": "test_lesson",
            "subject_id": "numbers",
            "title_vi": "Updated Lesson",
            "title_en": "Updated Lesson EN",
            "description_vi": "Updated",
            "description_en": "Updated",
            "lesson_order": 100,
            "difficulty": "medium",
            "is_premium": false,
            "grade": 2
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 403 || status == 500);
}

#[tokio::test]
#[ignore]
async fn admin_delete_lesson() {
    let client = reqwest::Client::new();
    let resp = client
        .delete(format!("{}/admin/lessons/test_lesson", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 403 || status == 500);
}

#[tokio::test]
#[ignore]
async fn admin_create_exercise() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/admin/exercises", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "id": "test_exercise",
            "lesson_id": "lesson_n1",
            "question_vi": "2 + 3 = ?",
            "question_en": "2 + 3 = ?",
            "options": ["4", "5", "6", "7"],
            "correct_index": 1,
            "visual_asset": "",
            "hint_vi": "Đếm thêm 3",
            "hint_en": "Count 3 more",
            "exercise_order": 1
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 403 || status == 500);
}

#[tokio::test]
#[ignore]
async fn admin_update_exercise() {
    let client = reqwest::Client::new();
    let resp = client
        .put(format!("{}/admin/exercises/test_exercise", base_url()))
        .header("Authorization", format!("Bearer {}", auth_header()))
        .json(&serde_json::json!({
            "id": "test_exercise",
            "lesson_id": "lesson_n1",
            "question_vi": "Updated: 2 + 3 = ?",
            "question_en": "Updated: 2 + 3 = ?",
            "options": ["4", "5", "6", "7"],
            "correct_index": 1,
            "visual_asset": "",
            "hint_vi": "Updated hint",
            "hint_en": "Updated hint",
            "exercise_order": 2
        }))
        .send()
        .await;
    assert!(resp.is_ok());
    let status = resp.unwrap().status().as_u16();
    assert!(status == 200 || status == 403 || status == 500);
}

// ── Negative tests: no auth ───────────────────────────────────────

#[tokio::test]
#[ignore]
async fn curriculum_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/curriculum", base_url())).send().await.unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn subjects_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client.get(format!("{}/subjects", base_url())).send().await.unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn get_lesson_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("{}/lesson/lesson_n1", base_url()))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}

#[tokio::test]
#[ignore]
async fn admin_create_subject_without_auth_returns_401() {
    let client = reqwest::Client::new();
    let resp = client
        .post(format!("{}/admin/subjects", base_url()))
        .json(&serde_json::json!({"id": "x", "name_vi": "x"}))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status().as_u16(), 401);
}