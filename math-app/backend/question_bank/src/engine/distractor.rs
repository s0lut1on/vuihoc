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
}
