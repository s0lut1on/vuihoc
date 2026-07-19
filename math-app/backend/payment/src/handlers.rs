use crate::models::{AppState, CheckoutResponse, CreateCheckoutRequest, Subscription, SubscriptionStatus};
use axum::{extract::State, Json, Extension};
use axum::response::IntoResponse;
use shared::{health as shared_health, ApiResponse, Claims};
use uuid::Uuid;

pub async fn create_checkout_session(
    State(_state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateCheckoutRequest>,
) -> ApiResponse<CheckoutResponse> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let stripe_key = match std::env::var("STRIPE_SECRET_KEY") {
        Ok(key) => key,
        Err(_) => {
            tracing::warn!("STRIPE_SECRET_KEY not set, returning mock checkout URL");
            return ApiResponse::ok(CheckoutResponse {
                url: body.success_url.clone(),
            });
        }
    };

    let price_id = &body.price_id;
    let success_url = &body.success_url;
    let cancel_url = &body.cancel_url;

    let client = reqwest::Client::new();
    let params = serde_json::json!({
        "mode": "subscription",
        "line_items": [{
            "price": price_id,
            "quantity": 1
        }],
        "client_reference_id": user_id.to_string(),
        "customer_email": claims.email,
        "success_url": success_url,
        "cancel_url": cancel_url,
        "metadata": {
            "user_id": user_id.to_string()
        }
    });

    match client
        .post("https://api.stripe.com/v1/checkout/sessions")
        .header("Authorization", format!("Bearer {}", stripe_key))
        .header("Content-Type", "application/json")
        .json(&params)
        .send()
        .await
    {
        Ok(resp) if resp.status().is_success() => {
            let data: serde_json::Value = resp.json().await.unwrap_or_default();
            let url = data["url"].as_str().unwrap_or(success_url).to_string();
            ApiResponse::ok(CheckoutResponse { url })
        }
        Ok(resp) => {
            let text = resp.text().await.unwrap_or_default();
            tracing::error!("Stripe API error: {}", text);
            ApiResponse::err("Failed to create checkout session")
        }
        Err(e) => {
            tracing::error!("Stripe request failed: {}", e);
            ApiResponse::err("Failed to connect to payment provider")
        }
    }
}

pub async fn stripe_webhook(
    State(state): State<AppState>,
    req: axum::extract::Request,
) -> axum::response::Response {
    use axum::body::Bytes;
    let body = match axum::body::to_bytes(req.into_body(), 1024 * 1024).await {
        Ok(b) => b,
        Err(_) => return (axum::http::StatusCode::BAD_REQUEST, "Body too large").into_response(),
    };
    let event: serde_json::Value = match serde_json::from_slice(&body) {
        Ok(v) => v,
        Err(_) => return (axum::http::StatusCode::BAD_REQUEST, "Invalid JSON").into_response(),
    };

    let event_type = event["type"].as_str().unwrap_or("");
    match event_type {
        "checkout.session.completed" => {
            let session = &event["data"]["object"];
            let user_id_str = session["client_reference_id"].as_str().unwrap_or("");
            let customer_id = session["customer"].as_str().unwrap_or("");
            let subscription_id = session["subscription"].as_str().unwrap_or("");

            if let Ok(user_id) = Uuid::try_parse(user_id_str) {
                let _ = sqlx::query(
                    "INSERT INTO subscriptions (id, user_id, stripe_subscription_id, stripe_customer_id, tier, status, current_period_start)
                     VALUES ($1, $2, $3, $4, 'premium', 'active', NOW())
                     ON CONFLICT (user_id) DO UPDATE SET
                         stripe_subscription_id = $3,
                         stripe_customer_id = $4,
                         tier = 'premium',
                         status = 'active',
                         updated_at = NOW()",
                )
                .bind(Uuid::new_v4())
                .bind(user_id)
                .bind(subscription_id.to_string())
                .bind(customer_id.to_string())
                .execute(&state.db)
                .await;
            }
        }
        _ => {}
    }

    (axum::http::StatusCode::OK, "ok").into_response()
}

pub async fn get_subscription_status(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> ApiResponse<SubscriptionStatus> {
    let user_id = match Uuid::try_parse(&claims.sub) {
        Ok(id) => id,
        Err(_) => return ApiResponse::err("Invalid user ID"),
    };

    let result = sqlx::query_as::<_, Subscription>(
        "SELECT * FROM subscriptions WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1",
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await;

    match result {
        Ok(Some(sub)) => ApiResponse::ok(SubscriptionStatus {
            tier: sub.tier,
            is_active: sub.status == "active",
            period_end: sub.current_period_end,
        }),
        Ok(None) => ApiResponse::ok(SubscriptionStatus {
            tier: "free".to_string(),
            is_active: false,
            period_end: None,
        }),
        Err(e) => {
            tracing::error!("Database error in get_subscription_status: {}", e);
            ApiResponse::err("Internal server error")
        }
    }
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared_health("payment"))
}
