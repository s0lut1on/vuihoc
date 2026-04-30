use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Serialize, Deserialize, ToSchema, Clone)]
pub struct GoogleLoginRequest {
    pub id_token: String,
}

#[derive(Serialize, Deserialize, ToSchema, Clone)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub name: String,
    pub locale: Option<String>,
}

#[derive(Serialize, sqlx::FromRow, ToSchema, Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub email: String,
    pub name: String,
    pub persona: String,
    pub avatar: Option<String>,
    pub locale: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize, ToSchema)]
pub struct TokenResponse {
    pub access_token: String,
    pub token_type: String,
    pub expires_in: i64,
}

#[derive(Serialize, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,
    pub email: String,
    pub name: String,
    pub exp: usize,
}

#[derive(Deserialize)]
pub struct GoogleTokenInfo {
    pub sub: String,
    pub email: String,
    pub name: Option<String>,
    pub picture: Option<String>,
    pub given_name: Option<String>,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}
