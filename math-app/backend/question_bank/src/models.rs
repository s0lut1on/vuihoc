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

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct WrongAnswer {
    pub id: Option<Uuid>,
    pub user_id: Uuid,
    pub exercise_id: String,
    pub lesson_id: String,
    pub subject_id: String,
    pub question_vi: String,
    pub question_en: String,
    pub hint_vi: Option<String>,
    pub hint_en: Option<String>,
    pub options: Vec<String>,
    pub correct_index: i32,
    pub wrong_count: i32,
    pub last_wrong_at: Option<DateTime<Utc>>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ReviewEntry {
    pub exercise_id: String,
    pub lesson_id: String,
    pub subject_id: String,
    pub question_vi: String,
    pub question_en: String,
    pub hint_vi: Option<String>,
    pub hint_en: Option<String>,
    pub options: Vec<String>,
    pub correct_index: i32,
    pub wrong_count: i32,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct ReviewList {
    pub entries: Vec<ReviewEntry>,
}

#[derive(Debug, Deserialize, ToSchema)]
pub struct RecordWrongPayload {
    pub exercise_id: String,
    pub lesson_id: String,
    pub subject_id: String,
    pub question_vi: String,
    pub question_en: String,
    pub hint_vi: Option<String>,
    pub hint_en: Option<String>,
    pub options: Vec<String>,
    pub correct_index: i32,
}

#[derive(Debug, Serialize, ToSchema)]
pub struct RecordWrongResult {
    pub recorded: bool,
    pub wrong_count: i32,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct HintRequest {
    pub exercise_id: String,
    pub question_text: String,
    pub answer_history: Vec<String>,
    pub expected_answer: String,
    pub is_vietnamese: bool,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct HintResponse {
    pub hint: String,
    pub hint_en: String,
    pub from_cache: bool,
}

#[derive(Debug, Clone)]
#[allow(dead_code)]
pub struct SampledParams {
    pub params: HashMap<String, f64>,
    #[allow(dead_code)]
    pub estimated_difficulty: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bkt_update_correct_increases_mastery() {
        let state = BktState::default();
        let new_state = state.update(true);
        assert!(new_state.p_mastery > state.p_mastery);
        assert_eq!(new_state.attempt_count, 1);
    }

    #[test]
    fn bkt_update_wrong_stays_in_range() {
        let state = BktState::default();
        let new_state = state.update(false);
        assert!(new_state.p_mastery >= 0.0 && new_state.p_mastery <= 1.0);
        assert_eq!(new_state.attempt_count, 1);
    }

    #[test]
    fn bkt_mastered_threshold() {
        let mut state = BktState::default();
        state.p_mastery = 0.94;
        assert!(!state.is_mastered());
        state.p_mastery = 0.96;
        assert!(state.is_mastered());
    }

    #[test]
    fn bkt_difficulty_target_maps_correctly() {
        let mut state = BktState::default();
        state.p_mastery = 0.2;
        assert_eq!(state.difficulty_target(), 1);
        state.p_mastery = 0.4;
        assert_eq!(state.difficulty_target(), 2);
        state.p_mastery = 0.6;
        assert_eq!(state.difficulty_target(), 3);
        state.p_mastery = 0.8;
        assert_eq!(state.difficulty_target(), 4);
    }

    // --- Bayesian posterior math (default p_learn=0.2, p_slip=0.1, p_guess=0.2) ---

    fn approx(a: f64, b: f64, eps: f64) -> bool { (a - b).abs() < eps }

    #[test]
    fn bkt_correct_from_default_matches_posterior() {
        // prior p=0.1, slip=0.1, guess=0.2
        // p_obs_given_known = 0.9, p_obs_given_not = 0.2
        // p_obs = 0.9*0.1 + 0.2*0.9 = 0.09 + 0.18 = 0.27
        // p_known_given_obs = 0.09 / 0.27 = 1/3 ≈ 0.3333
        // p_new = 0.3333 + (1 - 0.3333) * 0.2 = 0.3333 + 0.1333 = 0.4666...
        let s = BktState::default();
        let next = s.update(true);
        assert!(approx(next.p_mastery, 0.4667, 0.001), "got {}", next.p_mastery);
    }

    #[test]
    fn bkt_wrong_from_default_matches_posterior() {
        // prior p=0.1, slip=0.1, guess=0.2
        // p_obs_given_known = 0.1, p_obs_given_not = 0.8
        // p_obs = 0.1*0.1 + 0.8*0.9 = 0.01 + 0.72 = 0.73
        // p_known_given_obs = 0.01 / 0.73 ≈ 0.01370
        // p_new = 0.01370 + (1 - 0.01370) * 0.2 ≈ 0.01370 + 0.19726 = 0.21096
        let s = BktState::default();
        let next = s.update(false);
        assert!(approx(next.p_mastery, 0.21096, 0.001), "got {}", next.p_mastery);
    }

    #[test]
    fn bkt_attempt_count_increments_every_update() {
        let s = BktState::default();
        let n1 = s.update(true);
        let n2 = n1.update(false);
        let n3 = n2.update(true);
        assert_eq!(n1.attempt_count, 1);
        assert_eq!(n2.attempt_count, 2);
        assert_eq!(n3.attempt_count, 3);
    }

    #[test]
    fn bkt_preserves_other_fields() {
        let mut s = BktState::default();
        s.p_learn = 0.35;
        s.p_slip = 0.25;
        s.p_guess = 0.30;
        let n = s.update(true);
        assert_eq!(n.p_learn, 0.35);
        assert_eq!(n.p_slip, 0.25);
        assert_eq!(n.p_guess, 0.30);
        assert_eq!(n.attempt_count, 1);
    }

    #[test]
    fn bkt_stays_in_unit_interval_through_long_sequence() {
        let mut s = BktState::default();
        for i in 0..200 {
            s = s.update(i % 2 == 0);
            assert!(s.p_mastery >= 0.0 && s.p_mastery <= 1.0, "i={i} got {}", s.p_mastery);
        }
    }

    #[test]
    fn bkt_pure_bayesian_when_p_learn_zero() {
        // p_learn=0 → new = p_known_given_obs (no learning step)
        // With prior 0.5, correct → p_known_given_obs = (0.9*0.5) / 0.55 = 0.8182
        let mut s = BktState::default();
        s.p_mastery = 0.5;
        s.p_learn = 0.0;
        let n = s.update(true);
        assert!(approx(n.p_mastery, 0.81818, 0.001), "got {}", n.p_mastery);
    }

    #[test]
    fn bkt_certain_knowledge_with_zero_slip_guess() {
        // p_slip=0, p_guess=0 → if observed correct, p_new = 1.0
        // p_obs_given_known = 1, p_obs_given_not = 0
        // p_obs = 1*p; p_known = 1; p_new = 1 + 0*0.2 = 1.0
        let mut s = BktState::default();
        s.p_slip = 0.0;
        s.p_guess = 0.0;
        let n = s.update(true);
        assert!(approx(n.p_mastery, 1.0, 0.0001));
    }

    #[test]
    fn bkt_impossible_observation_clamps() {
        // p_slip=1.0, p_guess=1.0: if correct, p_obs = 0*p + 1*(1-p) = 1-p
        // p_known_given_obs = 0; p_new = 0 + 1*0.2 = 0.2
        let mut s = BktState::default();
        s.p_slip = 1.0;
        s.p_guess = 1.0;
        let n = s.update(true);
        assert!(approx(n.p_mastery, 0.2, 0.0001));
    }

    #[test]
    fn bkt_zero_p_obs_falls_back_to_prior() {
        // p_slip=1, p_guess=0, prior=0: p_obs = 1*0 + 0*1 = 0 → branch falls back to prior
        // prior=0, p_learn=0.2 → new = 0 + 1*0.2 = 0.2
        let mut s = BktState::default();
        s.p_mastery = 0.0;
        s.p_slip = 1.0;
        s.p_guess = 0.0;
        let n = s.update(false);
        assert!(approx(n.p_mastery, 0.2, 0.0001), "got {}", n.p_mastery);
    }

    #[test]
    fn bkt_five_correct_approaches_one_monotonically() {
        // Successive correct answers should monotonically increase p
        let mut s = BktState::default();
        let mut prev = s.p_mastery;
        for _ in 0..5 {
            s = s.update(true);
            assert!(s.p_mastery > prev, "non-monotonic at {}", s.p_mastery);
            prev = s.p_mastery;
        }
        assert!(s.p_mastery > 0.7, "got {}", s.p_mastery);
    }

    #[test]
    fn bkt_wrong_from_high_prior_drops_significantly() {
        // From high prior 0.9, single wrong should drop p below 0.9
        // p_obs_given_known = 0.1, p_obs_given_not = 0.8
        // p_obs = 0.1*0.9 + 0.8*0.1 = 0.17
        // p_known_given_obs = 0.09 / 0.17 ≈ 0.5294
        // p_new = 0.5294 + 0.4706*0.2 ≈ 0.6235
        let mut s = BktState::default();
        s.p_mastery = 0.9;
        let n = s.update(false);
        assert!(n.p_mastery < 0.9);
        assert!(approx(n.p_mastery, 0.6235, 0.001), "got {}", n.p_mastery);
    }

    #[test]
    fn bkt_difficulty_target_bin_85_returns_five() {
        let mut s = BktState::default();
        s.p_mastery = 0.85;
        assert_eq!(s.difficulty_target(), 5);
        s.p_mastery = 0.99;
        assert_eq!(s.difficulty_target(), 5);
    }

    #[test]
    fn bkt_is_mastered_exact_95_returns_true() {
        let mut s = BktState::default();
        s.p_mastery = 0.95;
        assert!(s.is_mastered());
    }

    #[test]
    fn bkt_default_state_values() {
        let s = BktState::default();
        assert_eq!(s.p_mastery, 0.1);
        assert_eq!(s.p_learn, 0.2);
        assert_eq!(s.p_slip, 0.1);
        assert_eq!(s.p_guess, 0.2);
        assert_eq!(s.attempt_count, 0);
        assert!(!s.is_mastered());
    }

    #[test]
    fn bkt_alternating_updates_stay_in_range() {
        // Pathological alternation should never break the invariant
        let mut s = BktState::default();
        for i in 0..50 {
            s = s.update(i % 3 == 0);
            assert!(s.p_mastery >= 0.0 && s.p_mastery <= 1.0);
        }
    }

    #[test]
    fn hint_response_serde_roundtrip() {
        let resp = HintResponse {
            hint: "Try counting!".to_string(),
            hint_en: "Try counting!".to_string(),
            from_cache: false,
        };
        let json = serde_json::to_string(&resp).unwrap();
        let decoded: HintResponse = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.hint, "Try counting!");
        assert_eq!(decoded.from_cache, false);
    }

    #[test]
    fn hint_request_serde_roundtrip() {
        let req = HintRequest {
            exercise_id: "ex1".to_string(),
            question_text: "1+1=?".to_string(),
            answer_history: vec!["3".to_string()],
            expected_answer: "2".to_string(),
            is_vietnamese: true,
        };
        let json = serde_json::to_string(&req).unwrap();
        let decoded: HintRequest = serde_json::from_str(&json).unwrap();
        assert_eq!(decoded.exercise_id, "ex1");
        assert_eq!(decoded.answer_history, vec!["3".to_string()]);
        assert!(decoded.is_vietnamese);
    }

    #[test]
    fn record_wrong_payload_fields() {
        let payload = RecordWrongPayload {
            exercise_id: "ex1".to_string(),
            lesson_id: "l1".to_string(),
            subject_id: "math".to_string(),
            question_vi: "1+1=?".to_string(),
            question_en: "1+1=?".to_string(),
            hint_vi: Some("Gợi ý".to_string()),
            hint_en: Some("Hint".to_string()),
            options: vec!["1".into(), "2".into()],
            correct_index: 1,
        };
        assert_eq!(payload.lesson_id, "l1");
        assert_eq!(payload.hint_en, Some("Hint".to_string()));
        assert_eq!(payload.options.len(), 2);
    }

    #[test]
    fn answer_result_has_feedback() {
        let result = AnswerResult {
            is_correct: true,
            correct_answer: 2.0,
            p_mastery_new: 0.5,
            is_mastered: false,
            feedback: "Good job!".to_string(),
        };
        let json = serde_json::to_string(&result).unwrap();
        assert!(json.contains("Good job"));
    }
}
