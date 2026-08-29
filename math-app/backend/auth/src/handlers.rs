use crate::models::{
    AppState, AuthUser, Claims, GoogleLoginRequest, GoogleTokenInfo, GuestLoginRequest, MeResponse,
    TokenResponse,
};
use axum::{
    extract::{Json, State},
    http::header::AUTHORIZATION,
    http::StatusCode,
};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use shared::ApiResponse;
use utoipa::OpenApi;

#[derive(OpenApi)]
#[openapi(components(schemas(
    GoogleLoginRequest,
    GuestLoginRequest,
    AuthUser,
    TokenResponse,
    MeResponse
)))]
pub struct ApiDoc;

pub async fn login_with_google(
    State(state): State<AppState>,
    Json(body): Json<GoogleLoginRequest>,
) -> ApiResponse<TokenResponse> {
    let client = reqwest::Client::new();

    // Support both id_token (mobile) and access_token (web GIS)
    let info: GoogleTokenInfo = if let Some(id_token) = &body.id_token {
        let resp = match client
            .post("https://oauth2.googleapis.com/tokeninfo")
            .form(&[("id_token", id_token.as_str())])
            .send()
            .await
        {
            Ok(r) => r,
            Err(_) => return ApiResponse::err("Failed to verify Google token"),
        };
        if !resp.status().is_success() {
            return ApiResponse::err("Invalid Google token");
        }
        match resp.json().await {
            Ok(d) => d,
            Err(_) => return ApiResponse::err("Invalid Google token response"),
        }
    } else if let Some(access_token) = &body.access_token {
        let url = "https://www.googleapis.com/oauth2/v2/userinfo";
        let resp = match client.get(url).bearer_auth(access_token).send().await {
            Ok(r) => r,
            Err(_) => return ApiResponse::err("Failed to verify Google access token"),
        };
        if !resp.status().is_success() {
            return ApiResponse::err("Invalid Google access token");
        }
        let userinfo: serde_json::Value = match resp.json().await {
            Ok(d) => d,
            Err(_) => return ApiResponse::err("Invalid Google userinfo response"),
        };
        GoogleTokenInfo {
            sub: userinfo["id"].as_str().unwrap_or("").to_owned(),
            email: userinfo["email"].as_str().unwrap_or("").to_owned(),
            name: userinfo["name"].as_str().map(|s| s.to_owned()),
            picture: userinfo["picture"].as_str().map(|s| s.to_owned()),
            given_name: userinfo["given_name"].as_str().map(|s| s.to_owned()),
        }
    } else {
        return ApiResponse::err("Missing id_token or access_token");
    };

    let name = info.name.clone().unwrap_or_else(|| {
        info.given_name
            .clone()
            .unwrap_or_else(|| "User".to_string())
    });

    let _ = sqlx::query(
        "INSERT INTO users (id, email, name, persona, avatar, locale)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT (email) DO UPDATE
         SET name = $3, avatar = COALESCE(users.avatar, $5)",
    )
    .bind(uuid::Uuid::new_v4())
    .bind(&info.email)
    .bind(&name)
    .bind("achiever")
    .bind(info.picture.as_deref().unwrap_or("🐸"))
    .bind("vi_VN")
    .execute(&state.db)
    .await;

    let db_user = sqlx::query_as::<_, AuthUser>("SELECT * FROM users WHERE email = $1")
        .bind(&info.email)
        .fetch_one(&state.db)
        .await;

    let (user_uuid, tier, role) = match db_user {
        Ok(u) => (u.id, u.subscription_tier, u.role),
        Err(_) => (uuid::Uuid::new_v4(), "free".to_string(), "child".to_string()),
    };

    let jwt_secret =
        std::env::var("JWT_SECRET").expect("JWT_SECRET environment variable must be set");
    let claims = Claims {
        sub: user_uuid.to_string(),
        email: info.email,
        name,
        picture: info.picture.clone().unwrap_or_default(),
        tier,
        role,
        exp: (Utc::now() + Duration::hours(24)).timestamp() as usize,
        aud: "math-app".to_string(),
    };
    let token = match encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret.as_ref()),
    ) {
        Ok(t) => t,
        Err(_) => return ApiResponse::err("Failed to generate token"),
    };
    ApiResponse::ok(TokenResponse {
        access_token: token,
        token_type: "Bearer".to_string(),
        expires_in: 86400,
    })
}

pub async fn me(headers: axum::http::HeaderMap) -> Result<ApiResponse<MeResponse>, StatusCode> {
    let auth_header = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    let token = auth_header.strip_prefix("Bearer ").unwrap_or(auth_header);

    if token.is_empty() {
        return Ok(ApiResponse::err("Missing authorization token"));
    }

    let jwt_secret =
        std::env::var("JWT_SECRET").expect("JWT_SECRET environment variable must be set");
    let decoding_key = DecodingKey::from_secret(jwt_secret.as_ref());
    let mut validation = Validation::default();
    validation.validate_exp = true;
    validation.aud = Some(std::collections::HashSet::from(["math-app".to_string()]));

    let decoded = match decode::<Claims>(token, &decoding_key, &validation) {
        Ok(data) => data,
        Err(_) => return Ok(ApiResponse::err("Invalid token")),
    };

    let claims = decoded.claims;
    Ok(ApiResponse::ok(MeResponse {
        id: claims.sub,
        email: claims.email.clone(),
        name: claims.name.clone(),
        picture: claims.picture,
        given_name: claims.name,
        tier: claims.tier,
        role: claims.role,
    }))
}

pub async fn refresh_token(
    headers: axum::http::HeaderMap,
) -> ApiResponse<TokenResponse> {
    let auth_header = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");
    let token = auth_header.strip_prefix("Bearer ").unwrap_or(auth_header);

    if token.is_empty() {
        return ApiResponse::err("Missing authorization token");
    }

    let jwt_secret =
        std::env::var("JWT_SECRET").expect("JWT_SECRET environment variable must be set");
    let decoding_key = DecodingKey::from_secret(jwt_secret.as_ref());
    let mut validation = Validation::default();
    // Accept expired tokens within a 7-day grace period so users don't lose
    // their session just because the token expired while the app was closed.
    validation.validate_exp = false;
    validation.aud = Some(std::collections::HashSet::from(["math-app".to_string()]));

    let decoded = match decode::<Claims>(token, &decoding_key, &validation) {
        Ok(data) => data,
        Err(_) => return ApiResponse::err("Invalid token"),
    };

    let claims = decoded.claims;

// Reject tokens older than 7 days since expiry
let now = Utc::now().timestamp() as usize;
if claims.exp + 604800 < now {
        return ApiResponse::err("Token expired beyond refresh grace period");
    }

    let new_claims = Claims {
        sub: claims.sub,
        email: claims.email,
        name: claims.name,
        picture: claims.picture,
        tier: claims.tier,
        role: claims.role,
        exp: (Utc::now() + Duration::hours(24)).timestamp() as usize,
        aud: "math-app".to_string(),
    };

    let token = match encode(
        &Header::default(),
        &new_claims,
        &EncodingKey::from_secret(jwt_secret.as_ref()),
    ) {
        Ok(t) => t,
        Err(_) => return ApiResponse::err("Failed to generate token"),
    };

    ApiResponse::ok(TokenResponse {
        access_token: token,
        token_type: "Bearer".to_string(),
        expires_in: 86400,
    })
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("auth"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::extract::Json;

    fn setup() {
        std::env::set_var("JWT_SECRET", "test-secret-for-unit-tests-only");
    }

    fn make_test_token() -> String {
        let claims = Claims {
            sub: "user-123".to_string(),
            email: "test@test.com".to_string(),
            name: "Test User".to_string(),
            picture: "".to_string(),
            tier: "free".to_string(),
            role: "child".to_string(),
            exp: (Utc::now() + Duration::days(1)).timestamp() as usize,
            aud: "math-app".to_string(),
        };
        let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "test-secret".to_string());
        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(jwt_secret.as_ref()),
        )
        .unwrap()
    }

    #[tokio::test]
    async fn health_returns_ok() {
        let resp = health().await;
        assert!(resp.success);
        assert_eq!(resp.data.unwrap().status, "ok");
    }

    #[tokio::test]
    async fn me_with_valid_token_returns_user() {
        setup();
        let token = make_test_token();
        let mut headers = axum::http::HeaderMap::new();
        headers.insert(AUTHORIZATION, format!("Bearer {}", token).parse().unwrap());
        let resp = me(headers).await.unwrap();
        assert!(resp.success);
        let data = resp.data.unwrap();
        assert_eq!(data.name, "Test User");
        assert_eq!(data.tier, "free");
        assert_eq!(data.id, "user-123");
    }

    #[tokio::test]
    async fn me_without_token_returns_error() {
        let headers = axum::http::HeaderMap::new();
        let resp = me(headers).await.unwrap();
        assert!(!resp.success);
        assert!(resp.error.is_some());
    }

    #[tokio::test]
    async fn me_with_invalid_token_returns_error() {
        setup();
        let mut headers = axum::http::HeaderMap::new();
        headers.insert(AUTHORIZATION, "Bearer invalid-token".parse().unwrap());
        let resp = me(headers).await.unwrap();
        assert!(!resp.success);
        assert!(resp.error.is_some());
    }
}

pub async fn login_as_guest(
    State(state): State<AppState>,
    Json(body): Json<GuestLoginRequest>,
) -> ApiResponse<TokenResponse> {
    let user_id = uuid::Uuid::new_v4();
    let email = format!("guest_{}@example.com", uuid::Uuid::new_v4());
    let name = body.name.clone().unwrap_or_else(|| "Guest".to_string());
    let locale = body.locale.clone().unwrap_or_else(|| "vi_VN".to_string());

    let insert_result = sqlx::query(
        "INSERT INTO users (id, email, name, persona, avatar, locale) VALUES ($1, $2, $3, $4, $5, $6)"
    )
    .bind(user_id)
    .bind(&email)
    .bind(&name)
    .bind("achiever")
    .bind("🐸")
    .bind(&locale)
    .execute(&state.db)
    .await;

    if insert_result.is_err() {
        return ApiResponse::err("Failed to create guest user");
    }

    let claims = Claims {
        sub: user_id.to_string(),
        email: email.clone(),
        name: name.clone(),
        picture: String::new(),
        tier: "free".to_string(),
        role: "child".to_string(),
        exp: (Utc::now() + Duration::hours(24 * 7)).timestamp() as usize,
        aud: "math-app".to_string(),
    };

    let jwt_secret =
        std::env::var("JWT_SECRET").expect("JWT_SECRET environment variable must be set");

    match encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret.as_ref()),
    ) {
        Ok(token) => ApiResponse::ok(TokenResponse {
            access_token: token,
            token_type: "Bearer".to_string(),
            expires_in: 86400 * 7,
        }),
        Err(_) => ApiResponse::err("Failed to generate token"),
    }
}
