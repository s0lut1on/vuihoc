use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Serialize, Deserialize, ToSchema, Clone)]
pub struct GoogleLoginRequest {
    pub id_token: Option<String>,
    pub access_token: Option<String>,
}

#[derive(Serialize, Deserialize, ToSchema, Clone)]
pub struct GuestLoginRequest {
    pub name: Option<String>,
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
    pub subscription_tier: String,
    pub role: String,
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
    #[serde(default)]
    pub picture: String,
    #[serde(default)]
    pub tier: String,
    #[serde(default)]
    pub role: String,
    pub exp: usize,
    #[serde(default = "default_aud")]
    pub aud: String,
}

fn default_aud() -> String {
    "math-app".to_string()
}

#[derive(Deserialize)]
pub struct GoogleTokenInfo {
    #[allow(dead_code)]
    pub sub: String,
    pub email: String,
    pub name: Option<String>,
    pub picture: Option<String>,
    pub given_name: Option<String>,
}

#[derive(Serialize, ToSchema)]
pub struct MeResponse {
    pub id: String,
    pub email: String,
    pub name: String,
    pub picture: String,
    pub given_name: String,
    pub tier: String,
    pub role: String,
}

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn google_login_request_serde_roundtrip() {
        let req = GoogleLoginRequest {
            id_token: Some("abc".to_string()),
            access_token: None,
        };
        let json = serde_json::to_string(&req).unwrap();
        let decoded: GoogleLoginRequest = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.id_token, Some("abc".to_string()));
        assert_eq!(decoded.access_token, None);
    }

    #[test]
    fn guest_login_request_serde_roundtrip() {
        let req = GuestLoginRequest {
            name: Some("Guest".to_string()),
            locale: Some("vi_VN".to_string()),
        };
        let json = serde_json::to_string(&req).unwrap();
        let decoded: GuestLoginRequest = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.name, Some("Guest".to_string()));
    }

    #[test]
    fn claims_serde_roundtrip() {
        let claims = Claims {
            sub: "user-123".to_string(),
            email: "test@test.com".to_string(),
            name: "Test".to_string(),
            picture: "https://pic.jpg".to_string(),
            tier: "free".to_string(),
            role: "child".to_string(),
            exp: 1234567890,
            aud: "math-app".to_string(),
        };
        let json = serde_json::to_string(&claims).unwrap();
        let decoded: Claims = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.sub, "user-123");
        assert_eq!(decoded.email, "test@test.com");
        assert_eq!(decoded.picture, "https://pic.jpg");
        assert_eq!(decoded.tier, "free");
        assert_eq!(decoded.role, "child");
    }

    #[test]
    fn claims_defaults_picture_and_tier() {
        let json = r#"{"sub":"u1","email":"e@e.com","name":"N","exp":1}"#;
        let claims: Claims = serde_json::from_str(json).unwrap();
        assert_eq!(claims.picture, "");
        assert_eq!(claims.tier, "");
        assert_eq!(claims.role, "");
    }

    #[test]
    fn token_response_fields() {
        let resp = TokenResponse {
            access_token: "tok".to_string(),
            token_type: "Bearer".to_string(),
            expires_in: 3600,
        };
        assert_eq!(resp.access_token, "tok");
        assert_eq!(resp.token_type, "Bearer");
        assert_eq!(resp.expires_in, 3600);
    }

    #[test]
    fn me_response_fields() {
        let resp = MeResponse {
            id: "u1".to_string(),
            email: "e@e.com".to_string(),
            name: "N".to_string(),
            picture: "pic.jpg".to_string(),
            given_name: "G".to_string(),
            tier: "premium".to_string(),
            role: "child".to_string(),
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("u1"));
        assert!(json.contains("premium"));
        assert!(json.contains("child"));
    }

    #[test]
    fn google_token_info_fields() {
        let info = GoogleTokenInfo {
            sub: "s".to_string(),
            email: "e@e.com".to_string(),
            name: Some("N".to_string()),
            picture: Some("p".to_string()),
            given_name: Some("G".to_string()),
        };
        assert_eq!(info.email, "e@e.com");
        assert_eq!(info.name, Some("N".to_string()));
    }

    #[test]
    fn auth_user_default_tier() {
        let user = AuthUser {
            id: Uuid::new_v4(),
            email: "e@e.com".to_string(),
            name: "N".to_string(),
            persona: "achiever".to_string(),
            avatar: Some("🐸".to_string()),
            locale: "vi_VN".to_string(),
            subscription_tier: "free".to_string(),
            role: "child".to_string(),
            created_at: Utc::now(),
        };
        assert_eq!(user.subscription_tier, "free");
        assert_eq!(user.role, "child");
    }
}
