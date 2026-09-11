use crate::email_template;
use crate::models::{AppState, Notification, NotificationPayload, NotificationPreferences, PushSubscription, ReportData, ReportSendResult, SubscribeRequest, SubscriptionStatus, UpdatePreferencesRequest};
use crate::report_data::{fetch_report_data, ReportPeriod};
use axum::{extract::{Path, State}, Json, Extension};
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
                parent_email: None,
                email_reports_enabled: false,
                report_frequency: "never".to_string(),
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
        "INSERT INTO notification_preferences (id, user_id, daily_reminder_enabled, reminder_hour, timezone, parent_email, email_reports_enabled, report_frequency)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT (user_id) DO UPDATE SET
             daily_reminder_enabled = COALESCE($3, notification_preferences.daily_reminder_enabled),
             reminder_hour = COALESCE($4, notification_preferences.reminder_hour),
             timezone = COALESCE($5, notification_preferences.timezone),
             parent_email = COALESCE($6, notification_preferences.parent_email),
             email_reports_enabled = COALESCE($7, notification_preferences.email_reports_enabled),
             report_frequency = COALESCE($8, notification_preferences.report_frequency),
             updated_at = NOW()
         RETURNING *",
    )
    .bind(Uuid::new_v4())
    .bind(user_id)
    .bind(body.daily_reminder_enabled)
    .bind(body.reminder_hour)
    .bind(body.timezone.as_deref().unwrap_or("Asia/Ho_Chi_Minh"))
    .bind(body.parent_email.as_deref())
    .bind(body.email_reports_enabled.unwrap_or(false))
    .bind(body.report_frequency.as_deref().unwrap_or("never"))
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

/// Simple HTML tag stripper for plain-text fallback.
fn strip_html(html: &str) -> String {
    let mut result = String::with_capacity(html.len());
    let mut in_tag = false;
    for ch in html.chars() {
        if ch == '<' {
            in_tag = true;
        } else if ch == '>' {
            in_tag = false;
            result.push(' ');
        } else if !in_tag {
            result.push(ch);
        }
    }
    result.split_whitespace().collect::<Vec<_>>().join(" ")
}

/// Send email reports to all parents with the given frequency preference.
async fn send_reports_for_frequency(
    state: &AppState,
    frequency: &str,
    period: ReportPeriod,
) -> ReportSendResult {
    let rows = sqlx::query_as::<_, (Uuid, Option<String>, String)>(
        "SELECT user_id, parent_email, COALESCE(timezone, 'Asia/Ho_Chi_Minh') FROM notification_preferences
         WHERE email_reports_enabled = true AND parent_email IS NOT NULL AND report_frequency = $1",
    )
    .bind(frequency)
    .fetch_all(&state.db)
    .await;

    let parents = match rows {
        Ok(data) => data,
        Err(e) => {
            tracing::error!("DB error fetching report recipients: {}", e);
            return ReportSendResult {
                sent: 0,
                failed: 0,
                skipped: 0,
                reason: Some(format!("DB error: {}", e)),
            };
        }
    };

    let api_key = match std::env::var("SENDGRID_API_KEY") {
        Ok(k) => k,
        Err(_) => {
            return ReportSendResult {
                sent: 0,
                failed: 0,
                skipped: parents.len(),
                reason: Some("SENDGRID_API_KEY not set".to_string()),
            };
        }
    };

    let client = reqwest::Client::new();
    let mut sent = 0;
    let mut failed = 0;
    let mut skipped = 0;

    for (user_id, parent_email, _tz) in &parents {
        let email = match parent_email {
            Some(e) if !e.is_empty() => e.clone(),
            _ => {
                skipped += 1;
                continue;
            }
        };

        let report_data = match fetch_report_data(&state.db, *user_id, period).await {
            Ok(d) => d,
            Err(e) => {
                tracing::error!("Failed to fetch report data for {}: {}", user_id, e);
                failed += 1;
                continue;
            }
        };

        let is_vi = report_data.locale == "vi";

        let html_body = match (period, is_vi) {
            (ReportPeriod::Daily, true) => email_template::render_daily_report_vi(&report_data),
            (ReportPeriod::Daily, false) => email_template::render_daily_report_en(&report_data),
            (ReportPeriod::Weekly, true) => email_template::render_weekly_report_vi(&report_data),
            (ReportPeriod::Weekly, false) => email_template::render_weekly_report_en(&report_data),
        };

        let plain_body = strip_html(&html_body);

        let subject = match (period, is_vi) {
            (ReportPeriod::Daily, true) => "Báo cáo học tập hôm nay của bé",
            (ReportPeriod::Daily, false) => "Your child's daily learning report",
            (ReportPeriod::Weekly, true) => "Báo cáo học tập tuần này của bé",
            (ReportPeriod::Weekly, false) => "Your child's weekly learning report",
        };

        let email_type = match period {
            ReportPeriod::Daily => "daily_report",
            ReportPeriod::Weekly => "weekly_report",
        };

        let body = serde_json::json!({
            "personalizations": [{"to": [{"email": email}]}],
            "from": {"email": "noreply@sekklings.com", "name": "HocVui"},
            "subject": subject,
            "content": [
                {"type": "text/html", "value": html_body},
                {"type": "text/plain", "value": plain_body}
            ]
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
                     VALUES ($1, $2, $3, $4, $5, $6, 'sent', NOW())",
                )
                .bind(Uuid::new_v4())
                .bind(user_id)
                .bind(&email)
                .bind(email_type)
                .bind(subject)
                .bind(&html_body)
                .execute(&state.db)
                .await;
                sent += 1;
            }
            Ok(resp) => {
                tracing::error!("SendGrid error for {}: status {}", email, resp.status());
                let _ = sqlx::query(
                    "INSERT INTO email_logs (id, user_id, email_to, email_type, subject, body, status)
                     VALUES ($1, $2, $3, $4, $5, $6, 'failed')",
                )
                .bind(Uuid::new_v4())
                .bind(user_id)
                .bind(&email)
                .bind(email_type)
                .bind(subject)
                .bind(&html_body)
                .execute(&state.db)
                .await;
                failed += 1;
            }
            Err(e) => {
                tracing::error!("SendGrid request failed for {}: {}", email, e);
                failed += 1;
            }
        }
    }

    ReportSendResult {
        sent,
        failed,
        skipped,
        reason: None,
    }
}

pub async fn send_daily_report(State(state): State<AppState>) -> Json<ReportSendResult> {
    let result = send_reports_for_frequency(&state, "daily", ReportPeriod::Daily).await;
    Json(result)
}

pub async fn send_weekly_report(State(state): State<AppState>) -> Json<ReportSendResult> {
    let result = send_reports_for_frequency(&state, "weekly", ReportPeriod::Weekly).await;
    Json(result)
}

/// Backward-compat alias — calls send_weekly_report logic.
pub async fn send_report(State(state): State<AppState>) -> String {
    let result = send_reports_for_frequency(&state, "weekly", ReportPeriod::Weekly).await;
    format!(
        "Sent {} reports, {} failed, {} skipped",
        result.sent, result.failed, result.skipped
    )
}

pub async fn get_report_data(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(user_id): Path<Uuid>,
) -> ApiResponse<ReportData> {
    let requester_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    if requester_id != user_id && claims.role != "admin" {
        return ApiResponse::err("Not authorized to view this user's report");
    }

    match fetch_report_data(&state.db, user_id, ReportPeriod::Weekly).await {
        Ok(data) => ApiResponse::ok(data),
        Err(e) => {
            tracing::error!("Failed to fetch report data: {}", e);
            ApiResponse::err("Failed to fetch report data")
        }
    }
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared_health("notification"))
}
