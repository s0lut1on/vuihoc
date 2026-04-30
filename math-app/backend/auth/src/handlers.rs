use crate::models::{
    AppState, AuthUser, Claims, GoogleLoginRequest, GoogleTokenInfo, RegisterRequest, TokenResponse,
};
use axum::extract::{Json, State};
use chrono::{Duration, Utc};
use jsonwebtoken::{encode, EncodingKey, Header};
use shared::ApiResponse;
use utoipa::OpenApi;

#[derive(OpenApi)]
#[openapi(components(schemas(GoogleLoginRequest, AuthUser, TokenResponse)))]
pub struct ApiDoc;

pub async fn login_with_google(
    State(state): State<AppState>,
    Json(body): Json<GoogleLoginRequest>,
) -> ApiResponse<TokenResponse> {
    let client = reqwest::Client::new();
    let url = format!(
        "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token={}",
        body.id_token
    );
    let resp = match client.get(&url).send().await {
        Ok(r) => r,
        Err(_) => return ApiResponse::err("Failed to verify Google token"),
    };
    if !resp.status().is_success() {
        return ApiResponse::err("Invalid Google token");
    }
    let info: GoogleTokenInfo = match resp.json().await {
        Ok(d) => d,
        Err(_) => return ApiResponse::err("Invalid Google token response"),
    };
    let name = info.name.clone().unwrap_or_else(|| {
        info.given_name
            .clone()
            .unwrap_or_else(|| "User".to_string())
    });
    let user_id = uuid::Uuid::new_v4();
    let _ = sqlx::query("INSERT INTO users (id, email, name, persona, avatar, locale) VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT (email) DO UPDATE SET name = $3, avatar = COALESCE(users.avatar, $5)")
        .bind(user_id)
        .bind(&info.email)
        .bind(&name)
        .bind("achiever")
        .bind(info.picture.as_deref().unwrap_or("🐸"))
        .bind("vi_VN")
        .execute(&state.db)
        .await;
    let claims = Claims {
        sub: info.sub,
        email: info.email,
        name,
        exp: (Utc::now() + Duration::hours(24)).timestamp() as usize,
    };
    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret("secret".as_ref()),
    )
    .unwrap_or_default();
    ApiResponse::ok(TokenResponse {
        access_token: token,
        token_type: "Bearer".to_string(),
        expires_in: 86400,
    })
}

pub async fn register(Json(body): Json<RegisterRequest>) -> ApiResponse<TokenResponse> {
    let claims = Claims {
        sub: uuid::Uuid::new_v4().to_string(),
        email: body.email,
        name: body.name,
        exp: (Utc::now() + Duration::hours(24)).timestamp() as usize,
    };
    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret("secret".as_ref()),
    )
    .unwrap_or_default();
    ApiResponse::ok(TokenResponse {
        access_token: token,
        token_type: "Bearer".to_string(),
        expires_in: 86400,
    })
}

pub async fn me() -> ApiResponse<AuthUser> {
    ApiResponse::ok(AuthUser {
        id: uuid::Uuid::new_v4(),
        email: "be@example.com".to_string(),
        name: "Be Minh Anh".to_string(),
        persona: "achiever".to_string(),
        avatar: Some("🐸".to_string()),
        locale: "vi_VN".to_string(),
        created_at: Utc::now(),
    })
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("auth"))
}
