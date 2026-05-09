use axum::{response::IntoResponse, Json};
use chrono::{DateTime, Utc};
use serde::Serialize;
use utoipa::ToSchema;

#[derive(Serialize, Clone, ToSchema)]
pub struct HealthResponse {
    pub status: String,
    pub service: String,
    pub timestamp: DateTime<Utc>,
}

pub fn health(service: &'static str) -> HealthResponse {
    HealthResponse {
        status: "ok".into(),
        service: service.into(),
        timestamp: Utc::now(),
    }
}

#[derive(Serialize, ToSchema)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    pub data: Option<T>,
    pub error: Option<String>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn ok(data: T) -> ApiResponse<T> {
        ApiResponse {
            success: true,
            data: Some(data),
            error: None,
        }
    }
    pub fn err(msg: &str) -> ApiResponse<T> {
        ApiResponse {
            success: false,
            data: None,
            error: Some(msg.into()),
        }
    }
}

impl<T: Serialize> IntoResponse for ApiResponse<T> {
    fn into_response(self) -> axum::response::Response {
        Json(self).into_response()
    }
}

use axum::{extract::Request, http::header::AUTHORIZATION, http::StatusCode, middleware::Next};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::Deserialize;

#[derive(Debug, Deserialize, Clone)]
pub struct Claims {
    pub sub: String,
    pub email: String,
    pub name: String,
    pub picture: String,
    pub tier: String,
    pub exp: usize,
}

pub async fn auth_middleware(request: Request, next: Next) -> axum::response::Response {
    let auth_header = request
        .headers()
        .get(AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    let token = auth_header.strip_prefix("Bearer ").unwrap_or(auth_header);

    if token.is_empty() {
        return (
            StatusCode::UNAUTHORIZED,
            Json(ApiResponse::<()>::err("Missing authorization token")),
        )
            .into_response();
    }

    let jwt_secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| "test-secret".to_string());
    let decoding_key = DecodingKey::from_secret(jwt_secret.as_ref());
    let mut validation = Validation::default();
    validation.validate_exp = true;

    match decode::<Claims>(token, &decoding_key, &validation) {
        Ok(data) => {
            let mut req = request;
            req.extensions_mut().insert(data.claims);
            next.run(req).await
        }
        Err(_) => (
            StatusCode::UNAUTHORIZED,
            Json(ApiResponse::<()>::err("Invalid or expired token")),
        )
            .into_response(),
    }
}

#[derive(Serialize, ToSchema)]
pub struct Pagination {
    pub page: u32,
    pub per_page: u32,
    pub total: u64,
}

#[derive(Serialize, ToSchema)]
pub struct PaginatedResponse<T: Serialize> {
    pub data: Vec<T>,
    pub pagination: Pagination,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn health_has_status_ok() {
        let resp = health("test-svc");
        assert_eq!(resp.status, "ok");
        assert_eq!(resp.service, "test-svc");
    }

    #[test]
    fn api_response_ok_contains_data() {
        let resp = ApiResponse::ok("hello");
        assert_eq!(resp.success, true);
        assert_eq!(resp.data, Some("hello"));
        assert!(resp.error.is_none());
    }

    #[test]
    fn api_response_err_has_no_data() {
        let resp: ApiResponse<bool> = ApiResponse::err("failed");
        assert_eq!(resp.success, false);
        assert!(resp.data.is_none());
        assert_eq!(resp.error, Some("failed".to_string()));
    }

    #[test]
    fn health_timestamp_is_recent() {
        let before = Utc::now();
        let resp = health("svc");
        let after = Utc::now();
        assert!(resp.timestamp >= before);
        assert!(resp.timestamp <= after);
    }

    #[test]
    fn pagination_fields() {
        let p = Pagination {
            page: 2,
            per_page: 10,
            total: 55,
        };
        assert_eq!(p.page, 2);
        assert_eq!(p.per_page, 10);
        assert_eq!(p.total, 55);
    }

    #[test]
    fn api_response_ok_with_vec() {
        let resp: ApiResponse<Vec<String>> =
            ApiResponse::ok(vec!["a".to_string(), "b".to_string()]);
        assert!(resp.success);
        assert_eq!(resp.data.unwrap().len(), 2);
    }

    #[test]
    fn api_response_err_typed_string() {
        let resp: ApiResponse<String> = ApiResponse::err("oops");
        assert!(!resp.success);
        assert!(resp.data.is_none());
        assert_eq!(resp.error, Some("oops".to_string()));
    }

    #[test]
    fn paginated_response_fields() {
        let resp = PaginatedResponse {
            data: vec!["a".to_string(), "b".to_string()],
            pagination: Pagination {
                page: 1,
                per_page: 10,
                total: 2,
            },
        };
        let json = serde_json::to_string(&resp).unwrap();
        assert!(json.contains("a"));
        assert!(json.contains("page"));
        assert!(json.contains("1"));
    }
}
