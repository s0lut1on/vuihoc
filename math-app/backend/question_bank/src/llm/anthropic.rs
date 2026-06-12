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
- Đảm bảo đáp án vẫn là {answer}"#,
            grade = grade, bare_stem = bare_stem, answer = answer, domain = domain
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

    pub async fn generate_hint(
        &self,
        question_text: &str,
        answer_history: &[String],
        is_vietnamese: bool,
    ) -> Result<String> {
        let language = if is_vietnamese { "Tiếng Việt" } else { "English" };
        let prompt = format!(
            r#"You are a friendly Vietnamese math tutor for 6-year-olds (Kindergarten).

Exercise: "{}"
Child's wrong answers so far: {:?}

Provide ONE short, gentle hint in {} (maximum 20 words).
CRITICAL RULES:
1. Do NOT give the correct answer directly.
2. Give only a nudge that helps the child think.
3. If it's a counting exercise, suggest they count slowly.
4. If it's an addition exercise, suggest they look at the numbers again.
5. Keep it under 20 words.
6. The tone should be encouraging and gentle.

Return ONLY the hint, nothing else."#,
            question_text, answer_history, language
        );

        let req = AnthropicRequest {
            model: MODEL.into(),
            max_tokens: 100,
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

pub fn hint_contains_answer(hint: &str, answer: &str) -> bool {
    let hint_lower = hint.to_lowercase();
    let answer_lower = answer.to_lowercase();
    hint_lower.contains(&answer_lower)
}

pub fn llm_available() -> bool {
    std::env::var("ANTHROPIC_API_KEY").is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hint_contains_answer_detects_exact_match() {
        assert!(hint_contains_answer("The answer is 7", "7"));
        assert!(hint_contains_answer("Try counting: 1,2,3,4,5,6,7 fingers!", "7"));
    }

    #[test]
    fn hint_contains_answer_case_insensitive() {
        assert!(hint_contains_answer("Think about TÊN in Vietnamese", "tên"));
    }

    #[test]
    fn hint_does_not_contain_answer() {
        assert!(!hint_contains_answer("Count the objects in the picture", "7"));
        assert!(!hint_contains_answer("What comes after 3?", "4"));
    }

    #[test]
    fn llm_available_returns_false_when_key_missing() {
        std::env::remove_var("ANTHROPIC_API_KEY");
        assert!(!llm_available());
    }
}
