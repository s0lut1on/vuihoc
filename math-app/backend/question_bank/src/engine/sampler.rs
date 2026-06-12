use crate::models::{ParamConstraint, SampledParams};
use anyhow::{bail, Result};
use rand::Rng;
use std::collections::HashMap;

const MAX_RETRY: usize = 100;
const DIFFICULTY_TOLERANCE: f64 = 0.5;

pub fn sample_params(
    param_schema: &HashMap<String, ParamConstraint>,
    target_difficulty: i32,
) -> Result<SampledParams> {
    let mut rng = rand::thread_rng();

    for _ in 0..MAX_RETRY {
        let mut params = HashMap::new();

        for (name, constraint) in param_schema {
            let value = sample_one(&mut rng, constraint);
            params.insert(name.clone(), value);
        }

        if !validate_mathematical(&params) {
            continue;
        }

        let estimated = estimate_difficulty(&params);
        if (estimated - target_difficulty as f64).abs() <= DIFFICULTY_TOLERANCE {
            return Ok(SampledParams {
                params,
                estimated_difficulty: estimated,
            });
        }
    }

    bail!(
        "Could not sample valid params with difficulty {}",
        target_difficulty
    )
}

fn sample_one<R: Rng>(rng: &mut R, c: &ParamConstraint) -> f64 {
    loop {
        let v = if c.integer_only {
            rng.gen_range(c.min as i64..=c.max as i64) as f64
        } else {
            rng.gen_range(c.min..=c.max)
        };
        if !c.exclude_zero || v != 0.0 {
            return v;
        }
    }
}

fn estimate_difficulty(params: &HashMap<String, f64>) -> f64 {
    let magnitude_score: f64 =
        params.values().map(|v| v.abs()).sum::<f64>() / params.len().max(1) as f64;

    let sign_complexity: f64 = params.values().filter(|&&v| v < 0.0).count() as f64;

    let has_decimal: f64 = params.values().filter(|&&v| v.fract() != 0.0).count() as f64 * 1.5;

    let raw = 1.0 + (magnitude_score / 10.0) + sign_complexity * 0.5 + has_decimal;
    raw.clamp(1.0, 5.0)
}

fn validate_mathematical(params: &HashMap<String, f64>) -> bool {
    if let Some(&a) = params.get("a") {
        if a == 0.0 {
            return false;
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn estimate_difficulty_low_values() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 1.0);
        p.insert("b".to_string(), 2.0);
        let d = estimate_difficulty(&p);
        assert!(d >= 1.0 && d < 2.0);
    }

    #[test]
    fn estimate_difficulty_clamped_to_5() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 100.0);
        p.insert("b".to_string(), -50.0);
        let d = estimate_difficulty(&p);
        assert!(d <= 5.0);
    }

    #[test]
    fn estimate_difficulty_empty_params() {
        let p: HashMap<String, f64> = HashMap::new();
        let d = estimate_difficulty(&p);
        assert!((d - 1.0).abs() < 0.01);
    }

    #[test]
    fn estimate_difficulty_negative_increases() {
        let mut pos = HashMap::new();
        pos.insert("a".to_string(), 5.0);
        let mut neg = HashMap::new();
        neg.insert("a".to_string(), -5.0);
        assert!(estimate_difficulty(&neg) > estimate_difficulty(&pos));
    }

    #[test]
    fn validate_mathematical_rejects_zero_a() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 0.0);
        assert!(!validate_mathematical(&p));
    }

    #[test]
    fn validate_mathematical_allows_nonzero_a() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 1.0);
        assert!(validate_mathematical(&p));
    }

    #[test]
    fn validate_mathematical_allows_no_a() {
        let mut p = HashMap::new();
        p.insert("b".to_string(), 0.0);
        assert!(validate_mathematical(&p));
    }
}
