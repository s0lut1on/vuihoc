use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
#[allow(dead_code)]
pub struct BktState {
    pub id: Option<Uuid>,
    pub student_id: Uuid,
    pub kc_id: Uuid,
    pub p_mastery: f64,
    pub p_learn: f64,
    pub p_slip: f64,
    pub p_guess: f64,
    pub attempt_count: i32,
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
        }
    }
}

impl BktState {
    #[allow(dead_code)]
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

    #[allow(dead_code)]
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mastery_increases_on_correct() {
        let state = BktState::default();
        let after = state.update(true);
        assert!(after.p_mastery > state.p_mastery);
    }

    #[test]
    fn test_five_correct_answers_near_mastery() {
        let mut state = BktState::default();
        for _ in 0..5 {
            state = state.update(true);
        }
        assert!(state.p_mastery > 0.7);
    }
}
