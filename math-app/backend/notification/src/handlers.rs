use crate::models::{AppState, Notification, NotificationPayload, NotificationPreferences, PushSubscription, ReminderResult, SubscribeRequest, SubscriptionStatus, UpdatePreferencesRequest};
use axum::{extract::State, Json, Extension};
use chrono::Utc;
use shared::{health as shared_health, ApiResponse, Claims};
use uuid::Uuid;

pub async fn list_notifications(State(state): State<AppState>) -> ApiResponse<Vec<Notification>> {
    let rows = sqlx::query_as::<_, Notification>(
        "SELECT * FROM notifications ORDER BY created_at DESC LIMIT 20",
    )
    .fetch_all(&state.db)
    .await;
    match rows {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Database error in list_notifications: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn send_test_notification(
    State(state): State<AppState>,
    Json(body): Json<NotificationPayload>,
) -> ApiResponse<Notification> {
    let id = Uuid::new_v4();
    let result = sqlx::query_as::<_, Notification>(
        "INSERT INTO notifications (id, user_id, title_vi, title_en, body_vi, body_en) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *",
    )
    .bind(id)
    .bind(Uuid::try_parse(&body.user_id).unwrap_or_else(|_| Uuid::new_v4()))
    .bind(&body.title_vi)
    .bind(&body.title_en)
    .bind(&body.body_vi)
    .bind(&body.body_en)
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(n) => ApiResponse::ok(n),
        Err(_) => ApiResponse::err("Failed to send notification"),
    }
}

pub async fn subscribe_push(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<SubscribeRequest>,
) -> ApiResponse<PushSubscription> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let id = Uuid::new_v4();
    let result = sqlx::query_as::<_, PushSubscription>(
        "INSERT INTO push_subscriptions (id, user_id, fcm_token, platform, is_active) 
         VALUES ($1, $2, $3, $4, true) 
         ON CONFLICT (fcm_token) DO UPDATE SET user_id = $2, platform = $4, is_active = true, updated_at = NOW()
         RETURNING *",
    )
    .bind(id)
    .bind(user_id)
    .bind(&body.fcm_token)
    .bind(&body.platform)
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(sub) => ApiResponse::ok(sub),
        Err(e) => {
            tracing::error!("Database error in subscribe_push: {}", e);
            ApiResponse::err("Failed to subscribe")
        }
    }
}

pub async fn unsubscribe_push(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> ApiResponse<String> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let result = sqlx::query(
        "UPDATE push_subscriptions SET is_active = false, updated_at = NOW() WHERE user_id = $1",
    )
    .bind(user_id)
    .execute(&state.db)
    .await;

    match result {
        Ok(_) => ApiResponse::ok("Unsubscribed".to_string()),
        Err(e) => {
            tracing::error!("Database error in unsubscribe_push: {}", e);
            ApiResponse::err("Failed to unsubscribe")
        }
    }
}

pub async fn get_subscription_status(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> ApiResponse<SubscriptionStatus> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let result = sqlx::query_as::<_, PushSubscription>(
        "SELECT * FROM push_subscriptions WHERE user_id = $1 AND is_active = true LIMIT 1",
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await;

    match result {
        Ok(Some(sub)) => ApiResponse::ok(SubscriptionStatus {
            subscribed: true,
            platform: Some(sub.platform),
        }),
        Ok(None) => ApiResponse::ok(SubscriptionStatus {
            subscribed: false,
            platform: None,
        }),
        Err(e) => {
            tracing::error!("Database error in get_subscription_status: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn get_preferences(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> ApiResponse<NotificationPreferences> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let result = sqlx::query_as::<_, NotificationPreferences>(
        "SELECT * FROM notification_preferences WHERE user_id = $1",
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await;

    match result {
        Ok(Some(prefs)) => ApiResponse::ok(prefs),
        Ok(None) => {
            // Return default preferences
            ApiResponse::ok(NotificationPreferences {
                id: Uuid::new_v4(),
                user_id,
                daily_reminder_enabled: true,
                reminder_hour: 19,
                timezone: "Asia/Ho_Chi_Minh".to_string(),
                created_at: Utc::now(),
                updated_at: Utc::now(),
            })
        }
        Err(e) => {
            tracing::error!("Database error in get_preferences: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn update_preferences(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<UpdatePreferencesRequest>,
) -> ApiResponse<NotificationPreferences> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let result = sqlx::query_as::<_, NotificationPreferences>(
        "INSERT INTO notification_preferences (id, user_id, daily_reminder_enabled, reminder_hour, timezone)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (user_id) DO UPDATE SET
             daily_reminder_enabled = COALESCE($3, notification_preferences.daily_reminder_enabled),
             reminder_hour = COALESCE($4, notification_preferences.reminder_hour),
             timezone = COALESCE($5, notification_preferences.timezone),
             updated_at = NOW()
         RETURNING *",
    )
    .bind(Uuid::new_v4())
    .bind(user_id)
    .bind(body.daily_reminder_enabled)
    .bind(body.reminder_hour)
    .bind(body.timezone.as_deref().unwrap_or("Asia/Ho_Chi_Minh"))
    .fetch_one(&state.db)
    .await;

    match result {
        Ok(prefs) => ApiResponse::ok(prefs),
        Err(e) => {
            tracing::error!("Database error in update_preferences: {}", e);
            ApiResponse::err("Failed to update preferences")
        }
    }
}

pub async fn send_reminders(State(state): State<AppState>) -> String {
    let now = Utc::now();
    let current_hour = ((now.timestamp() % 86400) / 3600) as i32;

    let rows = sqlx::query_as::<_, (Uuid, String, String)>(
        "SELECT ps.user_id, ps.fcm_token, ps.platform
         FROM push_subscriptions ps
         JOIN notification_preferences np ON ps.user_id = np.user_id
         WHERE ps.is_active = true
           AND np.daily_reminder_enabled = true
           AND np.reminder_hour = $1",
    )
    .bind(current_hour)
    .fetch_all(&state.db)
    .await;

    let subscriptions = match rows {
        Ok(data) => data,
        Err(e) => {
            tracing::error!("Database error in send_reminders: {}", e);
            return format!("Error: {}", e);
        }
    };

    let fcm_client = match crate::fcm::FcmClient::new() {
        Some(client) => client,
        None => {
            tracing::warn!("FCM not configured, skipping reminder send");
            return format!("FCM not configured, skipped {} subscriptions", subscriptions.len());
        }
    };

    let mut sent_count = 0;
    let mut failed_count = 0;

    for (user_id, token, _platform) in subscriptions {
        let title_vi = "HocVui - Nhắc nhở học bài";
        let body_vi = "Bé ơi, hôm nay mình học toán nhé! 🐸📚";

        match fcm_client.send_message(&token, title_vi, body_vi).await {
            Ok(()) => {
                sent_count += 1;
                let _ = sqlx::query(
                    "INSERT INTO notifications (id, user_id, title_vi, title_en, body_vi, body_en)
                     VALUES ($1, $2, $3, $4, $5, $6)",
                )
                .bind(Uuid::new_v4())
                .bind(user_id)
                .bind(title_vi)
                .bind("HocVui - Daily Reminder")
                .bind(body_vi)
                .bind("Time to practice math! 🐸📚")
                .execute(&state.db)
                .await;
            }
            Err(e) => {
                tracing::error!("Failed to send FCM message to {}: {}", user_id, e);
                failed_count += 1;
            }
        }
    }

    format!("Sent {} reminders, {} failed", sent_count, failed_count)
}

pub async fn send_report(State(state): State<AppState>) -> String {
    let rows = sqlx::query_as::<_, (Uuid, String)>(
        "SELECT user_id, parent_email FROM notification_preferences
         WHERE email_reports_enabled = true AND parent_email IS NOT NULL",
    )
    .fetch_all(&state.db)
    .await;

    let parents = match rows {
        Ok(data) => data,
        Err(e) => return format!("DB error: {}", e),
    };

    let api_key = match std::env::var("SENDGRID_API_KEY") {
        Ok(k) => k,
        Err(_) => return format!("SENDGRID_API_KEY not set, skipping {} reports", parents.len()),
    };

    let client = reqwest::Client::new();
    let mut sent = 0;

    for (_user_id, email) in &parents {
        let body = serde_json::json!({
            "personalizations": [{"to": [{"email": email}]}],
            "from": {"email": "noreply@sekklings.com", "name": "HocVui"},
            "subject": "Báo cáo học tập tuần này của bé",
            "content": [{
                "type": "text/plain",
                "value": &format!(
                    "Chào phụ huynh,\n\nTuần này bé đã hoàn thành các bài học. \
                     Xem chi tiết tại: https://sekklings.com/parent-dashboard\n\nHocVui"
                )
            }]
        });

        match client
            .post("https://api.sendgrid.com/v3/mail/send")
            .header("Authorization", format!("Bearer {}", api_key))
            .header("Content-Type", "application/json")
            .json(&body)
            .send()
            .await
        {
            Ok(resp) if resp.status().is_success() => {
                let _ = sqlx::query(
                    "INSERT INTO email_logs (id, user_id, email_to, email_type, subject, body, status, sent_at)
                     VALUES ($1, $2, $3, 'weekly_report', 'Báo cáo học tập', $4, 'sent', NOW())",
                )
                .bind(Uuid::new_v4())
                .bind(_user_id)
                .bind(email)
                .bind("Weekly report")
                .execute(&state.db)
                .await;
                sent += 1;
            }
            Ok(_) => tracing::error!("SendGrid error for {}", email),
            Err(e) => tracing::error!("SendGrid request failed: {}", e),
        }
    }

    format!("Sent {} reports", sent)
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared_health("notification"))
}
