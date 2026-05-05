use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use std::collections::HashMap;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Kc {
    pub id: Option<Uuid>,
    pub name: String,
    pub description: String,
    pub bloom_level: String,
    pub difficulty_min: i32,
    pub difficulty_max: i32,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
#[allow(dead_code)]
pub struct KcEdge {
    pub kc_id: Uuid,
    pub prerequisite_kc_id: Uuid,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub struct ParamConstraint {
    pub min: f64,
    pub max: f64,
    #[serde(default)]
    pub integer_only: bool,
    #[serde(default)]
    pub exclude_zero: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct QuestionTemplate {
    pub id: Option<Uuid>,
    pub kc_id: Uuid,
    pub difficulty: i32,
    pub bloom_level: String,
    pub stem_template: String,
    pub param_schema: serde_json::Value,
    pub solution_expr: String,
    pub error_taxonomy: serde_json::Value,
    pub active: bool,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Question {
    pub id: Option<Uuid>,
    pub template_id: Uuid,
    pub kc_id: Uuid,
    pub difficulty: i32,
    pub stem: String,
    pub params: serde_json::Value,
    pub answer: f64,
    pub distractors: serde_json::Value,
    pub context_wrap: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
#[allow(dead_code)]
pub struct Student {
    pub id: Option<Uuid>,
    pub user_id: Uuid,
    pub name: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct BktState {
    pub id: Option<Uuid>,
    pub student_id: Uuid,
    pub kc_id: Uuid,
    pub p_mastery: f64,
    pub p_learn: f64,
    pub p_slip: f64,
    pub p_guess: f64,
    pub attempt_count: i32,
    pub updated_at: Option<DateTime<Utc>>,
}

impl Default for BktState {
    fn default() -> Self {
        Self {
            id: None,
            student_id: Uuid::nil(),
            kc_id: Uuid::nil(),
            p_mastery: 0.1,
            p_learn: 0.2,
            p_slip: 0.1,
            p_guess: 0.2,
            attempt_count: 0,
            updated_at: None,
        }
    }
}

impl BktState {
    pub fn update(&self, is_correct: bool) -> Self {
        let p = self.p_mastery;
        let p_obs_given_known = if is_correct {
            1.0 - self.p_slip
        } else {
            self.p_slip
        };
        let p_obs_given_not = if is_correct {
            self.p_guess
        } else {
            1.0 - self.p_guess
        };
        let p_obs = p_obs_given_known * p + p_obs_given_not * (1.0 - p);
        let p_known_given_obs = if p_obs > 0.0 {
            (p_obs_given_known * p) / p_obs
        } else {
            p
        };
        let p_new = p_known_given_obs + (1.0 - p_known_given_obs) * self.p_learn;
        Self {
            p_mastery: p_new.clamp(0.0, 1.0),
            attempt_count: self.attempt_count + 1,
            ..self.clone()
        }
    }

    pub fn is_mastered(&self) -> bool {
        self.p_mastery >= 0.95
    }

    #[allow(dead_code)]
    pub fn difficulty_target(&self) -> i32 {
        match self.p_mastery {
            p if p < 0.3 => 1,
            p if p < 0.5 => 2,
            p if p < 0.7 => 3,
            p if p < 0.85 => 4,
            _ => 5,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct AnswerPayload {
    pub question_id: Uuid,
    pub kc_id: Uuid,
    pub answer_given: f64,
    pub time_taken_ms: i32,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct AnswerResult {
    pub is_correct: bool,
    pub correct_answer: f64,
    pub p_mastery_new: f64,
    pub is_mastered: bool,
    pub feedback: String,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct GenerateRequest {
    pub kc_id: Uuid,
    pub difficulty: i32,
    pub count: i32,
    #[serde(default)]
    pub use_llm_wrap: bool,
    pub domain: Option<String>,
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct SampledParams {
    pub params: HashMap<String, f64>,
    #[allow(dead_code)]
    pub estimated_difficulty: f64,
}
