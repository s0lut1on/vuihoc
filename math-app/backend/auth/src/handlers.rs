use crate::models::{
    AppState, AuthUser, Claims, GoogleLoginRequest, GoogleTokenInfo, GuestLoginRequest, MeResponse,
    RegisterRequest, TokenResponse,
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
        let url = format!(
            "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token={}",
            id_token
        );
        let resp = match client.get(&url).send().await {
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
        picture: info.picture.clone().unwrap_or_default(),
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
        picture: String::new(),
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

pub async fn me(headers: axum::http::HeaderMap) -> Result<ApiResponse<MeResponse>, StatusCode> {
    let auth_header = headers
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    let token = auth_header.strip_prefix("Bearer ").unwrap_or(auth_header);

    if token.is_empty() {
        return Ok(ApiResponse::err("Missing authorization token"));
    }

    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "secret".to_string());
    let decoding_key = DecodingKey::from_secret(jwt_secret.as_ref());
    let mut validation = Validation::default();
    validation.validate_exp = false; // Allow expired tokens for simplicity in dev

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
    }))
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("auth"))
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
        exp: (Utc::now() + Duration::hours(24 * 365)).timestamp() as usize,
    };

    match encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret("secret".as_ref()),
    ) {
        Ok(token) => ApiResponse::ok(TokenResponse {
            access_token: token,
            token_type: "Bearer".to_string(),
            expires_in: 86400 * 365,
        }),
        Err(_) => ApiResponse::err("Failed to generate token"),
    }
}
