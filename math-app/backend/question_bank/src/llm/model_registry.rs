use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing;

/// Static registry JSON embedded at compile time.
/// Edit `model_registry.json` in the crate root and recompile to update.
const REGISTRY_JSON: &str = include_str!("../../model_registry.json");

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Provider {
    pub base_url: String,
    pub env_key: Option<String>,
    pub api_style: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ModelSpec {
    pub id: String,
    pub provider: String,
    pub cost_input_per_1m: f64,
    pub cost_output_per_1m: f64,
    pub speed: String,
    pub vietnamese_quality: String,
    pub max_tokens: u32,
    pub strengths: Vec<String>,
    pub context_length: u32,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AgentSpec {
    pub description: String,
    pub required_strengths: Vec<String>,
    pub preferred_vietnamese_quality: String,
    pub max_output_tokens: u32,
    pub priority: Vec<String>,
    pub candidates: Vec<String>,
    pub fallback: Option<String>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Registry {
    pub providers: HashMap<String, Provider>,
    pub models: Vec<ModelSpec>,
    pub agents: HashMap<String, AgentSpec>,
}

impl Registry {
    /// Load the embedded JSON registry.
    pub fn load() -> anyhow::Result<Self> {
        let reg: Registry = serde_json::from_str(REGISTRY_JSON)?;
        Ok(reg)
    }

    /// Resolve which model to use for a given agent.
    ///
    /// Logic:
    /// 1. Walk candidates in order.
    /// 2. Check provider env key is present (or null for local).
    /// 3. Check model max_tokens >= agent max_output_tokens.
    /// 4. Pick first match; if none, use fallback (Anthropic direct).
    pub fn resolve_for_agent(&self, agent_name: &str) -> ModelChoice {
        let agent = match self.agents.get(agent_name) {
            Some(a) => a,
            None => {
                tracing::warn!("Agent '{}' not found in registry, using fallback", agent_name);
                return self.fallback_choice();
            }
        };

        for candidate_id in &agent.candidates {
            let model = match self.models.iter().find(|m| &m.id == candidate_id) {
                Some(m) => m,
                None => continue,
            };

            if model.max_tokens < agent.max_output_tokens {
                tracing::debug!("Candidate {} rejected: max_tokens {} < required {}",
                    candidate_id, model.max_tokens, agent.max_output_tokens);
                continue;
            }

            let provider = match self.providers.get(&model.provider) {
                Some(p) => p,
                None => continue,
            };

            // If env_key is set, the env var must exist.
            if let Some(ref key) = provider.env_key {
                if std::env::var(key).is_err() {
                    tracing::debug!("Provider {} unavailable: {} not set", model.provider, key);
                    continue;
                }
            }

            return ModelChoice {
                model_id: model.id.clone(),
                provider_name: model.provider.clone(),
                api_style: provider.api_style.clone(),
                base_url: provider.base_url.clone(),
                api_key: provider.env_key.as_ref().and_then(|k| std::env::var(k).ok()),
                max_tokens: agent.max_output_tokens,
            };
        }

        // No candidate matched — use agent fallback (Anthropic direct).
        if let Some(ref fallback) = agent.fallback {
            if fallback.starts_with("anthropic:") {
                let model_id = fallback.strip_prefix("anthropic:").unwrap_or(fallback);
                if let Ok(key) = std::env::var("ANTHROPIC_API_KEY") {
                    return ModelChoice {
                        model_id: model_id.to_string(),
                        provider_name: "anthropic".to_string(),
                        api_style: "anthropic".to_string(),
                        base_url: "https://api.anthropic.com".to_string(),
                        api_key: Some(key),
                        max_tokens: agent.max_output_tokens,
                    };
                }
            }
        }

        self.fallback_choice()
    }

    /// Generic fallback — first available model from the global fallback agent.
    fn fallback_choice(&self) -> ModelChoice {
        if let Some(fb) = self.agents.get("fallback") {
            for candidate_id in &fb.candidates {
                if let Some(model) = self.models.iter().find(|m| &m.id == candidate_id) {
                    if let Some(provider) = self.providers.get(&model.provider) {
                        let has_key = provider
                            .env_key
                            .as_ref()
                            .map(|k| std::env::var(k).is_ok())
                            .unwrap_or(true);
                        if has_key {
                            return ModelChoice {
                                model_id: model.id.clone(),
                                provider_name: model.provider.clone(),
                                api_style: provider.api_style.clone(),
                                base_url: provider.base_url.clone(),
                                api_key: provider
                                    .env_key
                                    .as_ref()
                                    .and_then(|k| std::env::var(k).ok()),
                                max_tokens: fb.max_output_tokens,
                            };
                        }
                    }
                }
            }
        }

        // Ultimate fallback: hard-coded Anthropic Sonnet (old behaviour).
        let anthropic_key = std::env::var("ANTHROPIC_API_KEY").ok();
        ModelChoice {
            model_id: "claude-sonnet-4-20250514".to_string(),
            provider_name: "anthropic".to_string(),
            api_style: "anthropic".to_string(),
            base_url: "https://api.anthropic.com".to_string(),
            api_key: anthropic_key,
            max_tokens: 300,
        }
    }

    /// Return true if any LLM is available (non-fallback).
    pub fn llm_available(&self) -> bool {
        // If ANTHROPIC_API_KEY is set, we consider it available.
        if std::env::var("ANTHROPIC_API_KEY").is_ok() {
            return true;
        }
        // Or any ollama-cloud / local provider with a key present.
        for model in &self.models {
            if let Some(provider) = self.providers.get(&model.provider) {
                let has_key = provider
                    .env_key
                    .as_ref()
                    .map(|k| std::env::var(k).is_ok())
                    .unwrap_or(true);
                if has_key {
                    return true;
                }
            }
        }
        false
    }
}

#[derive(Debug, Clone)]
pub struct ModelChoice {
    pub model_id: String,
    pub provider_name: String,
    pub api_style: String,
    pub base_url: String,
    pub api_key: Option<String>,
    pub max_tokens: u32,
}

impl ModelChoice {
    /// True if this choice has an API key (or local provider needs none).
    pub fn is_usable(&self) -> bool {
        // Anthropic and ollama-cloud require key; local-ollama does not.
        if self.provider_name == "local-ollama" {
            return true;
        }
        self.api_key.is_some()
    }

    /// A friendly string for logging.
    pub fn display(&self) -> String {
        format!(
            "{} via {} (style={}, max_tokens={})",
            self.model_id, self.provider_name, self.api_style, self.max_tokens
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn registry_loads() {
        let reg = Registry::load().unwrap();
        assert!(!reg.models.is_empty());
        assert!(!reg.agents.is_empty());
    }

    #[test]
    fn resolve_hint_generator_fallback_without_keys() {
        let reg = Registry::load().unwrap();
        // Without any env keys set, this should still return *something*.
        let choice = reg.resolve_for_agent("hint_generator");
        assert!(!choice.model_id.is_empty());
    }
}
