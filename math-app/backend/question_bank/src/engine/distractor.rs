use rand::Rng;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Distractor {
    pub value: f64,
    #[allow(dead_code)]
    pub error_type: String,
}

pub fn generate_distractors(
    correct: f64,
    params: &HashMap<String, f64>,
    error_taxonomy: &[String],
    n: usize,
) -> Vec<f64> {
    let mut rng = rand::thread_rng();
    let mut distractors: Vec<Distractor> = Vec::new();

    for error_type in error_taxonomy {
        let candidate = match error_type.as_str() {
            "sign_flip" => params.get("b").map(|b| correct + 2.0 * b),
            "arithmetic_slip" => {
                let delta = rng.gen_range(-2..=2) as f64;
                Some(correct + delta)
            }
            "forgot_divide" => params.get("a").map(|a| correct * a),
            "wrong_order" => match (params.get("b"), params.get("c")) {
                (Some(b), Some(c)) => params.get("a").map(|a| (b + c) / a),
                _ => None,
            },
            "negated_answer" => Some(-correct),
            _ => None,
        };

        if let Some(val) = candidate {
            if is_valid_distractor(val, correct, &distractors) {
                distractors.push(Distractor {
                    value: round2(val),
                    error_type: error_type.clone(),
                });
            }
        }
    }

    while distractors.len() < n {
        let noise: f64 = rng.gen_range(-5..=5) as f64;
        let val = correct + noise;
        if is_valid_distractor(val, correct, &distractors) {
            distractors.push(Distractor {
                value: round2(val),
                error_type: "random_noise".into(),
            });
        }
    }

    distractors.into_iter().take(n).map(|d| d.value).collect()
}

fn is_valid_distractor(val: f64, correct: f64, existing: &[Distractor]) -> bool {
    val != correct && val.is_finite() && !existing.iter().any(|d| (d.value - val).abs() < 0.01)
}

fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round2_whole_number() {
        assert_eq!(round2(5.0), 5.0);
    }

    #[test]
    fn round2_decimal_rounds() {
        assert_eq!(round2(3.456), 3.46);
        assert_eq!(round2(3.454), 3.45);
    }

    #[test]
    fn is_valid_distractor_rejects_correct_answer() {
        let existing = vec![];
        assert!(!is_valid_distractor(5.0, 5.0, &existing));
    }

    #[test]
    fn is_valid_distractor_rejects_duplicate() {
        let existing = vec![Distractor { value: 3.0, error_type: "test".into() }];
        assert!(!is_valid_distractor(3.0, 5.0, &existing));
    }

    #[test]
    fn is_valid_distractor_rejects_infinity() {
        let existing = vec![];
        assert!(!is_valid_distractor(f64::INFINITY, 5.0, &existing));
    }

    #[test]
    fn is_valid_distractor_accepts_novel_value() {
        let existing = vec![Distractor { value: 3.0, error_type: "test".into() }];
        assert!(is_valid_distractor(4.0, 5.0, &existing));
    }

    #[test]
    fn generate_distractors_sign_flip_uses_b() {
        let mut params = HashMap::new();
        params.insert("b".to_string(), 2.0);
        // correct=5, sign_flip => 5 + 2*2 = 9
        let d = generate_distractors(5.0, &params, &["sign_flip".to_string()], 3);
        assert!(d.contains(&9.0));
    }

    #[test]
    fn generate_distractors_negated_answer() {
        let params = HashMap::new();
        let d = generate_distractors(7.0, &params, &["negated_answer".to_string()], 1);
        assert_eq!(d[0], -7.0);
    }

    #[test]
    fn generate_distractors_returns_exact_n() {
        let params = HashMap::new();
        let taxonomy: Vec<String> = vec![];
        let d = generate_distractors(5.0, &params, &taxonomy, 4);
        assert_eq!(d.len(), 4);
    }

    #[test]
    fn generate_distractors_all_unique() {
        let params = HashMap::new();
        let taxonomy: Vec<String> = vec![];
        let d = generate_distractors(10.0, &params, &taxonomy, 5);
        let seen: std::collections::HashSet<i64> =
            d.iter().map(|v| (v * 100.0).round() as i64).collect();
        assert_eq!(seen.len(), d.len());
    }

    // ---- error taxonomy semantics ----

    fn p(b: f64) -> HashMap<String, f64> {
        let mut m = HashMap::new();
        m.insert("b".to_string(), b);
        m
    }
    fn pa(a: f64) -> HashMap<String, f64> {
        let mut m = HashMap::new();
        m.insert("a".to_string(), a);
        m
    }
    fn pbc(b: f64, c: f64) -> HashMap<String, f64> {
        let mut m = HashMap::new();
        m.insert("b".to_string(), b);
        m.insert("c".to_string(), c);
        m
    }

    #[test]
    fn sign_flip_uses_param_b_when_present() {
        // correct=5, b=2 → 5 + 2*2 = 9
        let d = generate_distractors(5.0, &p(2.0), &["sign_flip".to_string()], 1);
        assert_eq!(d, vec![9.0]);
    }

    #[test]
    fn sign_flip_without_b_falls_back() {
        // No b param → None → not added; falls through to random noise
        let d = generate_distractors(5.0, &HashMap::new(), &["sign_flip".to_string()], 1);
        // Should still return 1 distractor (random noise), not crash
        assert_eq!(d.len(), 1);
    }

    #[test]
    fn negated_answer_always_inverts() {
        // 7 → -7 (deterministic, n=1 forces the neg candidate)
        let d = generate_distractors(7.0, &HashMap::new(), &["negated_answer".to_string()], 1);
        assert_eq!(d, vec![-7.0]);
        // -3 → 3 (deterministic)
        let d2 = generate_distractors(-3.0, &HashMap::new(), &["negated_answer".to_string()], 1);
        assert_eq!(d2, vec![3.0]);
    }

    #[test]
    fn negated_answer_for_zero_correct_does_not_emit_zero() {
        // For correct=0, -correct=0, which the validity check rejects
        // (val==correct). Result must NOT be 0.
        let d = generate_distractors(0.0, &HashMap::new(), &["negated_answer".to_string()], 1);
        assert_eq!(d.len(), 1);
        assert_ne!(d[0], 0.0);
    }

    #[test]
    fn arithmetic_slip_delta_in_noise_range() {
        // noise is rng.gen_range(-5..=5) so abs delta can be up to 5
        for _ in 0..50 {
            let d = generate_distractors(10.0, &HashMap::new(), &["arithmetic_slip".to_string()], 1);
            let delta = (d[0] - 10.0).abs();
            assert!(delta <= 5.0, "delta {} out of range", delta);
        }
    }

    #[test]
    fn forgot_divide_multiplies_by_a() {
        // correct=5, a=2 → 5*2=10
        let d = generate_distractors(5.0, &pa(2.0), &["forgot_divide".to_string()], 1);
        assert_eq!(d, vec![10.0]);
    }

    #[test]
    fn forgot_divide_without_a_falls_back() {
        let d = generate_distractors(5.0, &HashMap::new(), &["forgot_divide".to_string()], 1);
        assert_eq!(d.len(), 1); // noise
    }

    #[test]
    fn wrong_order_with_b_and_c_present() {
        // correct=5, b=2, c=4, a=10 → (2+4)/10 = 0.6
        let mut params = HashMap::new();
        params.insert("a".to_string(), 10.0);
        params.insert("b".to_string(), 2.0);
        params.insert("c".to_string(), 4.0);
        let d = generate_distractors(5.0, &params, &["wrong_order".to_string()], 1);
        assert_eq!(d, vec![0.6]);
    }

    #[test]
    fn wrong_order_without_bc_falls_back() {
        let d = generate_distractors(5.0, &HashMap::new(), &["wrong_order".to_string()], 1);
        assert_eq!(d.len(), 1); // noise
    }

    // ---- count and uniqueness ----

    #[test]
    fn generate_distractors_returns_exact_count_when_taxonomy_sufficient() {
        let d = generate_distractors(10.0, &p(2.0),
            &["sign_flip".to_string(), "negated_answer".to_string()], 4);
        assert_eq!(d.len(), 4);
    }

    #[test]
    fn generate_distractors_handles_n_zero() {
        let d = generate_distractors(10.0, &HashMap::new(), &[], 0);
        assert!(d.is_empty());
    }

    #[test]
    fn generate_distractors_no_collision_with_correct() {
        for _ in 0..30 {
            let d = generate_distractors(10.0, &HashMap::new(), &[], 5);
            for v in &d {
                assert_ne!(*v, 10.0, "distractor equals correct answer");
            }
        }
    }

    #[test]
    fn is_valid_distractor_rejects_nan() {
        let existing: Vec<Distractor> = vec![];
        assert!(!is_valid_distractor(f64::NAN, 5.0, &existing));
    }

    #[test]
    fn is_valid_distractor_rejects_positive_infinity() {
        let existing: Vec<Distractor> = vec![];
        assert!(!is_valid_distractor(f64::INFINITY, 5.0, &existing));
    }

    #[test]
    fn is_valid_distractor_rejects_negative_infinity() {
        let existing: Vec<Distractor> = vec![];
        assert!(!is_valid_distractor(f64::NEG_INFINITY, 5.0, &existing));
    }

    #[test]
    fn is_valid_distractor_accepts_zero_when_not_correct() {
        let existing: Vec<Distractor> = vec![];
        assert!(is_valid_distractor(0.0, 5.0, &existing));
    }

    #[test]
    fn round2_rounds_to_two_decimals() {
        assert_eq!(round2(3.456), 3.46);
        assert_eq!(round2(3.454), 3.45);
        assert_eq!(round2(0.0), 0.0);
        assert_eq!(round2(100.0), 100.0);
    }
}
