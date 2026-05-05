use anyhow::Result;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

const ANTHROPIC_API: &str = "https://api.anthropic.com/v1/messages";
const MODEL: &str = "claude-sonnet-4-20250514";

#[derive(Serialize)]
struct AnthropicRequest {
    model: String,
    max_tokens: u32,
    messages: Vec<Message>,
}

#[derive(Serialize, Deserialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Deserialize)]
struct AnthropicResponse {
    content: Vec<ContentBlock>,
}

#[derive(Deserialize)]
struct ContentBlock {
    #[serde(rename = "type")]
    block_type: String,
    text: Option<String>,
}

pub struct AnthropicClient {
    http: Client,
    api_key: String,
}

impl AnthropicClient {
    pub fn new(api_key: String) -> Self {
        Self {
            http: Client::new(),
            api_key,
        }
    }

    pub async fn wrap_word_problem(
        &self,
        bare_stem: &str,
        answer: f64,
        _params: &HashMap<String, f64>,
        domain: &str,
        grade: u8,
    ) -> Result<String> {
        let prompt = format!(
            r#"Bạn là giáo viên toán lớp {grade}.
Hãy viết bài toán thực tế ngắn gọn (2-3 câu) dựa trên phương trình sau:
Phương trình: {bare_stem}
Đáp án: {answer}
Domain: {domain} (ví dụ: mua sắm, nấu ăn, thể thao)

Yêu cầu:
- Ngôn ngữ: Tiếng Việt
- Phù hợp học sinh lớp {grade}
- Chỉ trả về đề bài, không giải
- Đảm bảo đáp án vẫn là {answer}"#
        );

        let req = AnthropicRequest {
            model: MODEL.into(),
            max_tokens: 300,
            messages: vec![Message {
                role: "user".into(),
                content: prompt,
            }],
        };

        let resp = self
            .http
            .post(ANTHROPIC_API)
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .json(&req)
            .send()
            .await?
            .json::<AnthropicResponse>()
            .await?;

        let text = resp
            .content
            .iter()
            .filter(|b| b.block_type == "text")
            .filter_map(|b| b.text.as_ref())
            .cloned()
            .collect::<Vec<_>>()
            .join("");

        Ok(text.trim().to_string())
    }
}
