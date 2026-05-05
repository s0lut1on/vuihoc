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
