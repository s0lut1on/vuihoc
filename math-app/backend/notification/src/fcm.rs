use jsonwebtoken::{encode, Algorithm, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Serialize, Deserialize)]
struct ServiceAccount {
    #[serde(rename = "type")]
    account_type: String,
    project_id: String,
    private_key_id: String,
    private_key: String,
    client_email: String,
    client_id: String,
    auth_uri: String,
    token_uri: String,
}

#[derive(Debug, Serialize)]
struct Claims {
    iss: String,
    sub: String,
    scope: String,
    aud: String,
    iat: u64,
    exp: u64,
}

#[derive(Debug, Deserialize)]
struct TokenResponse {
    access_token: String,
    token_type: String,
    expires_in: u64,
}

pub struct FcmClient {
    service_account: ServiceAccount,
    http_client: reqwest::Client,
}

impl FcmClient {
    pub fn new() -> Option<Self> {
        let json = std::env::var("FCM_SERVICE_ACCOUNT_JSON").ok()?;
        let service_account: ServiceAccount = serde_json::from_str(&json).ok()?;
        Some(Self {
            service_account,
            http_client: reqwest::Client::new(),
        })
    }

    async fn get_access_token(&self) -> Result<String, Box<dyn std::error::Error>> {
        let now = SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs();
        let claims = Claims {
            iss: self.service_account.client_email.clone(),
            sub: self.service_account.client_email.clone(),
            scope: "https://www.googleapis.com/auth/firebase.messaging".to_string(),
            aud: self.service_account.token_uri.clone(),
            iat: now,
            exp: now + 3600,
        };

        let header = Header::new(Algorithm::RS256);
        let key = EncodingKey::from_rsa_pem(self.service_account.private_key.as_bytes())?;
        let jwt = encode(&header, &claims, &key)?;

        let resp = self
            .http_client
            .post(&self.service_account.token_uri)
            .form(&[
                ("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer"),
                ("assertion", &jwt),
            ])
            .send()
            .await?;

        let token_resp: TokenResponse = resp.json().await?;
        Ok(token_resp.access_token)
    }

    pub async fn send_message(
        &self,
        token: &str,
        title: &str,
        body: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let access_token = self.get_access_token().await?;
        let url = format!(
            "https://fcm.googleapis.com/v1/projects/{}/messages:send",
            self.service_account.project_id
        );

        let payload = json!({
            "message": {
                "token": token,
                "notification": {
                    "title": title,
                    "body": body,
                },
                "android": {
                    "priority": "high",
                    "notification": {
                        "channel_id": "daily_reminder",
                        "sound": "default"
                    }
                },
                "apns": {
                    "payload": {
                        "aps": {
                            "sound": "default",
                            "badge": 1
                        }
                    }
                },
                "webpush": {
                    "notification": {
                        "icon": "/icons/icon-192x192.png",
                        "badge": "/icons/badge-72x72.png"
                    }
                }
            }
        });

        let resp = self
            .http_client
            .post(&url)
            .header("Authorization", format!("Bearer {}", access_token))
            .header("Content-Type", "application/json")
            .json(&payload)
            .send()
            .await?;

        if resp.status().is_success() {
            Ok(())
        } else {
            let text = resp.text().await?;
            Err(format!("FCM send failed: {}", text).into())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn service_account_parse() {
        let json = r#"{
            "type": "service_account",
            "project_id": "test-project",
            "private_key_id": "key123",
            "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIICXAIBAAKBgQC...\n-----END RSA PRIVATE KEY-----\n",
            "client_email": "test@test-project.iam.gserviceaccount.com",
            "client_id": "123456789",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token"
        }"#;
        let account: ServiceAccount = serde_json::from_str(json).unwrap();
        assert_eq!(account.project_id, "test-project");
    }
}
