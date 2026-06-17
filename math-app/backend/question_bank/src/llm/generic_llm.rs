use anyhow::{Context, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};

use crate::llm::model_registry::ModelChoice;

/// Generic OpenAI-compatible chat completions client.
/// Works for ollama-cloud, local-ollama, and any provider
/// exposing `/v1/chat/completions`.
pub struct GenericLlmClient {
    http: Client,
    api_key: Option<String>,
    base_url: String,
    model_id: String,
}

impl GenericLlmClient {
    pub fn new(choice: &ModelChoice) -> Self {
        Self {
            http: Client::new(),
            api_key: choice.api_key.clone(),
            base_url: choice.base_url.clone(),
            model_id: choice.model_id.clone(),
        }
    }

    /// Convenience constructor for Anthropic fallback.
    pub fn anthropic(api_key: String, model_id: String) -> Self {
        Self {
            http: Client::new(),
            api_key: Some(api_key),
            base_url: "https://api.anthropic.com".into(),
            model_id,
        }
    }

    /// Send a simple single-turn chat request and return the text content.
    pub async fn chat(&self, prompt: &str, max_tokens: u32) -> Result<String> {
        let url = format!("{}/v1/chat/completions", self.base_url);

        let body = ChatCompletionRequest {
            model: self.model_id.clone(),
            max_tokens: Some(max_tokens),
            messages: vec![Message {
                role: "user".into(),
                content: prompt.into(),
            }],
        };

        let mut req = self.http.post(&url).json(&body);
        if let Some(ref key) = self.api_key {
            req = req.header("Authorization", format!("Bearer {}", key));
        }

        let resp = req
            .send()
            .await
            .with_context(|| format!("POST {}", url))?
            .json::<ChatCompletionResponse>()
            .await
            .context("failed to parse chat completion response")?;

        let text = resp
            .choices
            .into_iter()
            .next()
            .map(|c| c.message.content)
            .unwrap_or_default();

        Ok(text.trim().to_string())
    }
}

// ------------------------------------------------------------------
// OpenAI-compatible request/response shapes
// ------------------------------------------------------------------

#[derive(Serialize)]
struct ChatCompletionRequest {
    model: String,
    max_tokens: Option<u32>,
    messages: Vec<Message>,
}

#[derive(Serialize, Deserialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Deserialize)]
struct ChatCompletionResponse {
    choices: Vec<Choice>,
}

#[derive(Deserialize)]
struct Choice {
    message: Message,
}
