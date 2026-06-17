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

    // ---- sample_one ----

    fn c(min: f64, max: f64, integer_only: bool, exclude_zero: bool) -> ParamConstraint {
        ParamConstraint {
            min,
            max,
            integer_only,
            exclude_zero,
        }
    }

    #[test]
    fn sample_one_integer_returns_integer() {
        let con = c(1.0, 10.0, true, false);
        for _ in 0..50 {
            let v = sample_one(&mut rand::thread_rng(), &con);
            assert_eq!(v, v.round(), "expected integer, got {}", v);
            assert!(v >= 1.0 && v <= 10.0);
        }
    }

    #[test]
    fn sample_integer_negative_range_works() {
        let con = c(-5.0, -1.0, true, false);
        for _ in 0..50 {
            let v = sample_one(&mut rand::thread_rng(), &con);
            assert_eq!(v, v.round());
            assert!(v >= -5.0 && v <= -1.0);
        }
    }

    #[test]
    fn sample_one_continuous_returns_real() {
        let con = c(0.0, 1.0, false, false);
        let v = sample_one(&mut rand::thread_rng(), &con);
        assert!(v >= 0.0 && v <= 1.0);
        // statistically unlikely to be a clean integer
        // (we just check it's in range; distribution is uniform)
    }

    #[test]
    fn sample_one_exclude_zero_skips_zero() {
        let con = c(-2.0, 2.0, true, true); // {-2,-1,0,1,2} \ {0}
        for _ in 0..100 {
            let v = sample_one(&mut rand::thread_rng(), &con);
            assert_ne!(v, 0.0, "exclude_zero failed");
            assert!(v >= -2.0 && v <= 2.0);
        }
    }

    #[test]
    fn sample_one_exclude_zero_with_no_zero_in_range_unchanged() {
        // If 0 is outside [min,max], exclude_zero has no effect
        let con = c(5.0, 10.0, true, true);
        for _ in 0..50 {
            let v = sample_one(&mut rand::thread_rng(), &con);
            assert!(v >= 5.0 && v <= 10.0);
        }
    }

    // ---- estimate_difficulty edge cases ----

    #[test]
    fn estimate_difficulty_all_zero_params_returns_one() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 0.0);
        p.insert("b".to_string(), 0.0);
        let d = estimate_difficulty(&p);
        assert!((d - 1.0).abs() < 0.01, "got {}", d);
    }

    #[test]
    fn estimate_difficulty_very_large_values_clamp_to_five() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 1_000_000.0);
        p.insert("b".to_string(), 999_999.0);
        let d = estimate_difficulty(&p);
        assert!(d <= 5.0, "got {}", d);
    }

    #[test]
    fn estimate_difficulty_many_negatives_increase_score() {
        let mut pos = HashMap::new();
        pos.insert("a".to_string(), 10.0);
        pos.insert("b".to_string(), 10.0);
        let mut neg = HashMap::new();
        neg.insert("a".to_string(), -10.0);
        neg.insert("b".to_string(), -10.0);
        assert!(estimate_difficulty(&neg) > estimate_difficulty(&pos));
    }

    #[test]
    fn estimate_difficulty_decimals_increase_score() {
        let mut ints = HashMap::new();
        ints.insert("a".to_string(), 5.0);
        ints.insert("b".to_string(), 5.0);
        let mut decs = HashMap::new();
        decs.insert("a".to_string(), 5.5);
        decs.insert("b".to_string(), 5.5);
        assert!(estimate_difficulty(&decs) > estimate_difficulty(&ints));
    }

    #[test]
    fn estimate_difficulty_empty_returns_one() {
        let p: HashMap<String, f64> = HashMap::new();
        let d = estimate_difficulty(&p);
        assert!((d - 1.0).abs() < 0.01);
    }

    // ---- validate_mathematical edge cases ----

    #[test]
    fn validate_mathematical_negative_a_allowed() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), -1.0);
        assert!(validate_mathematical(&p));
    }

    #[test]
    fn validate_mathematical_very_small_nonzero_a_allowed() {
        let mut p = HashMap::new();
        p.insert("a".to_string(), 0.0001);
        assert!(validate_mathematical(&p));
    }

    // ---- sample_params integration ----

    #[test]
    fn sample_params_with_wide_schema_handles_all_targets() {
        // Schema wide enough that target 1-5 is reachable
        let mut schema = HashMap::new();
        schema.insert("a".to_string(), c(1.0, 50.0, true, true));
        schema.insert("b".to_string(), c(-10.0, 50.0, true, false));
        for target in 1..=5 {
            let r = sample_params(&schema, target);
            assert!(r.is_ok(), "target {} failed: {:?}", target, r.err());
        }
    }
}
