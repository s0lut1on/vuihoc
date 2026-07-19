use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct Subscription {
    pub id: Uuid,
    pub user_id: Uuid,
    pub stripe_subscription_id: Option<String>,
    pub stripe_customer_id: Option<String>,
    pub tier: String,
    pub status: String,
    pub current_period_start: DateTime<Utc>,
    pub current_period_end: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Serialize, Deserialize, ToSchema)]
pub struct CreateCheckoutRequest {
    pub price_id: String,
    pub success_url: String,
    pub cancel_url: String,
}

#[derive(Serialize, ToSchema)]
pub struct CheckoutResponse {
    pub url: String,
}

#[derive(Serialize, ToSchema)]
pub struct SubscriptionStatus {
    pub tier: String,
    pub is_active: bool,
    pub period_end: Option<DateTime<Utc>>,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct PaymentHistory {
    pub id: Uuid,
    pub user_id: Uuid,
    pub stripe_payment_intent_id: Option<String>,
    pub amount: i64,
    pub currency: String,
    pub status: String,
    pub tier: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
