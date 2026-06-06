# Hướng Dẫn Triển Khai Hệ Thống Tự Sinh Question Bank bằng Rust

> **Stack:** Rust · SurrealDB · Tokio · Anthropic API  
> **Mức độ:** Intermediate → Advanced  
> **Thời gian ước tính:** 3–5 ngày để có prototype hoàn chỉnh

---

## Mục lục

1. [Lý thuyết nền tảng](#1-lý-thuyết-nền-tảng)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Chuẩn bị môi trường](#3-chuẩn-bị-môi-trường)
4. [Khởi tạo dự án Rust](#4-khởi-tạo-dự-án-rust)
5. [SurrealDB Schema & Setup](#5-surrealdb-schema--setup)
6. [Knowledge Component Graph](#6-knowledge-component-graph)
7. [Template Engine](#7-template-engine)
8. [Parameter Sampler](#8-parameter-sampler)
9. [Distractor Generator](#9-distractor-generator)
10. [Bayesian Knowledge Tracing](#10-bayesian-knowledge-tracing)
11. [Adaptive Question Selector](#11-adaptive-question-selector)
12. [LLM Augmentation với Anthropic API](#12-llm-augmentation-với-anthropic-api)
13. [HTTP API Layer](#13-http-api-layer)
14. [Chạy toàn bộ pipeline](#14-chạy-toàn-bộ-pipeline)
15. [Testing](#15-testing)

---

## 1. Lý thuyết nền tảng

### 1.1 Knowledge Component (KC)

Một KC là đơn vị kiến thức nhỏ nhất có thể đánh giá được. Ví dụ: "giải phương trình bậc nhất một ẩn" là một KC, khác với "rút gọn phân số".

**Nguyên tắc thiết kế KC:**
- Mỗi KC ánh xạ 1-1 với một kỹ năng cụ thể
- KC có quan hệ prerequisite với nhau → hình thành đồ thị có hướng (DAG)
- Không nên quá nhỏ (từng phép cộng) hay quá lớn ("đại số")

### 1.2 Parametric Question Template

Thay vì lưu câu hỏi tĩnh, ta lưu **skeleton** + **constraint**:

```
Template: "Giải {a}x + {b} = {c}"
Constraints: a ∈ [1,9], b ∈ [-9,9], c ∈ [-20,20], a ≠ 0
Solution: x = (c - b) / a
```

Với 1 template, có thể sinh ra hàng nghìn câu hỏi khác nhau về mặt số học nhưng cùng test một KC.

### 1.3 Distractor Taxonomy

Đáp án sai hiệu quả phải phản ánh **lỗi nhận thức thật sự** của học sinh:

| Loại lỗi | Ví dụ | Cách sinh |
|---|---|---|
| Đổi dấu sai | `ax = c + b` thay vì `c - b` | Flip sign của b |
| Nhầm thứ tự phép tính | Cộng trước chia sau | apply_wrong_order() |
| Trượt tính toán | Đáp án ± 1, ± 2 | Thêm noise nhỏ |
| Giải nửa chừng | Quên bước cuối | partial_solution() |

### 1.4 Bayesian Knowledge Tracing (BKT)

BKT mô hình hóa xác suất học sinh đã **thành thạo** một KC, dựa trên lịch sử trả lời:

```
Bốn tham số:
  p_init  = P(đã biết ngay từ đầu)     ~ 0.1 - 0.3
  p_learn = P(học được sau mỗi câu)    ~ 0.1 - 0.4
  p_slip  = P(biết nhưng trả lời sai)  ~ 0.05 - 0.2
  p_guess = P(không biết nhưng đúng)   ~ 0.1 - 0.25

Update sau mỗi câu trả lời:
  p_known_given_correct = (1 - p_slip) * p / ((1 - p_slip) * p + p_guess * (1-p))
  p_known_new = p_known + (1 - p_known) * p_learn
```

**Ngưỡng mastery** thường là `p_mastery >= 0.95`.

---

## 2. Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────────────┐
│                        HTTP API (Axum)                       │
│         /questions/next  /answers/submit  /students/:id      │
└──────────────────────────┬──────────────────────────────────┘
                           │
         ┌─────────────────▼─────────────────┐
         │          Core Engine              │
         │  ┌──────────┐  ┌───────────────┐  │
         │  │ Template │  │   Parameter   │  │
         │  │ Engine   │  │   Sampler     │  │
         │  └────┬─────┘  └──────┬────────┘  │
         │       │               │           │
         │  ┌────▼───────────────▼────────┐  │
         │  │    Question Generator       │  │
         │  │  + Distractor Engine        │  │
         │  └────────────┬───────────────┘  │
         │               │                  │
         │  ┌────────────▼───────────────┐  │
         │  │   BKT + Adaptive Selector  │  │
         │  └────────────┬───────────────┘  │
         └───────────────┼──────────────────┘
                         │
         ┌───────────────▼───────────────────┐
         │           SurrealDB               │
         │  kc | template | question |        │
         │  student | response | mastery      │
         └───────────────────────────────────┘
                         │
         ┌───────────────▼───────────────────┐
         │        Anthropic API              │
         │   (Word problem wrapper / LLM)    │
         └───────────────────────────────────┘
```

**Luồng dữ liệu chính:**
```
Author định nghĩa KC + Template
    → Generator sinh Question instances
        → Bank lưu vào SurrealDB
            → Adaptive Selector chọn câu phù hợp student
                → BKT cập nhật mastery sau khi student trả lời
```

---

## 3. Chuẩn bị môi trường

### 3.1 Cài đặt Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
rustup update stable

# Kiểm tra
rustc --version   # rustc 1.78+
cargo --version
```

### 3.2 Cài đặt SurrealDB

```bash
# macOS
brew install surrealdb/tap/surreal

# Linux
curl --proto '=https' --tlsv1.2 -sSf https://install.surrealdb.com | sh

# Khởi động local (development)
surreal start --log debug --user root --pass root memory

# Kiểm tra
surreal version
```

### 3.3 Biến môi trường

Tạo file `.env` ở root project:

```env
SURREAL_URL=ws://localhost:8000/rpc
SURREAL_USER=root
SURREAL_PASS=root
SURREAL_NS=qbank
SURREAL_DB=main

ANTHROPIC_API_KEY=sk-ant-...

HOST=127.0.0.1
PORT=3000
```

---

## 4. Khởi tạo dự án Rust

### 4.1 Tạo workspace

```bash
cargo new question_bank --name question_bank
cd question_bank
```

### 4.2 `Cargo.toml`

```toml
[package]
name = "question_bank"
version = "0.1.0"
edition = "2021"

[dependencies]
# Async runtime
tokio = { version = "1", features = ["full"] }

# Web framework
axum = { version = "0.7", features = ["json"] }
tower = "0.4"
tower-http = { version = "0.5", features = ["cors", "trace"] }

# SurrealDB
surrealdb = { version = "1.5", features = ["kv-mem"] }

# Serialization
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# HTTP client (Anthropic API)
reqwest = { version = "0.12", features = ["json"] }

# Error handling
anyhow = "1"
thiserror = "1"

# Templating
minijinja = "1"

# Math / Random
rand = "0.8"
statrs = "0.16"

# Config
dotenvy = "0.15"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
uuid = { version = "1", features = ["v4"] }
```

### 4.3 Cấu trúc thư mục

```
src/
├── main.rs
├── config.rs
├── db/
│   ├── mod.rs
│   └── client.rs
├── domain/
│   ├── mod.rs
│   ├── kc.rs           # Knowledge Component
│   ├── template.rs     # Question Template
│   ├── question.rs     # Generated Question
│   └── student.rs      # Student + BKT state
├── engine/
│   ├── mod.rs
│   ├── sampler.rs      # Parameter sampling
│   ├── generator.rs    # Question generation
│   ├── distractor.rs   # Distractor generation
│   └── bkt.rs          # Bayesian Knowledge Tracing
├── adaptive/
│   ├── mod.rs
│   └── selector.rs     # Adaptive question selection
├── llm/
│   ├── mod.rs
│   └── anthropic.rs    # LLM augmentation
└── api/
    ├── mod.rs
    ├── routes.rs
    └── handlers.rs
```

---

## 5. SurrealDB Schema & Setup

### 5.1 `src/db/client.rs`

```rust
use anyhow::Result;
use surrealdb::engine::remote::ws::{Client, Ws};
use surrealdb::opt::auth::Root;
use surrealdb::Surreal;

pub type Db = Surreal<Client>;

pub async fn connect(url: &str, user: &str, pass: &str, ns: &str, db: &str) -> Result<Db> {
    let client = Surreal::new::<Ws>(url).await?;
    client.signin(Root { username: user, password: pass }).await?;
    client.use_ns(ns).use_db(db).await?;
    Ok(client)
}
```

### 5.2 Schema migration

Tạo file `migrations/001_schema.surql`:

```sql
-- Knowledge Components
DEFINE TABLE kc SCHEMAFULL;
DEFINE FIELD name        ON kc TYPE string;
DEFINE FIELD description ON kc TYPE string;
DEFINE FIELD bloom_level ON kc TYPE string;  -- remember|understand|apply|analyze
DEFINE FIELD difficulty_min ON kc TYPE int;
DEFINE FIELD difficulty_max ON kc TYPE int;
DEFINE FIELD created_at  ON kc TYPE datetime DEFAULT time::now();

-- Prerequisite relationships (graph edge)
DEFINE TABLE prerequisite_of SCHEMAFULL;
DEFINE FIELD in  ON prerequisite_of TYPE record<kc>;
DEFINE FIELD out ON prerequisite_of TYPE record<kc>;

-- Question Templates
DEFINE TABLE template SCHEMAFULL;
DEFINE FIELD kc_id          ON template TYPE record<kc>;
DEFINE FIELD difficulty     ON template TYPE int ASSERT $value >= 1 AND $value <= 5;
DEFINE FIELD bloom_level    ON template TYPE string;
DEFINE FIELD stem_template  ON template TYPE string;  -- Jinja2-like: "Giải {{a}}x + {{b}} = {{c}}"
DEFINE FIELD param_schema   ON template TYPE object;  -- JSON constraints per param
DEFINE FIELD solution_expr  ON template TYPE string;  -- e.g. "(c - b) / a"
DEFINE FIELD error_taxonomy ON template TYPE array;
DEFINE FIELD active         ON template TYPE bool DEFAULT true;

-- Generated Questions
DEFINE TABLE question SCHEMAFULL;
DEFINE FIELD template_id ON question TYPE record<template>;
DEFINE FIELD kc_id       ON question TYPE record<kc>;
DEFINE FIELD difficulty  ON question TYPE int;
DEFINE FIELD stem        ON question TYPE string;
DEFINE FIELD params      ON question TYPE object;
DEFINE FIELD answer      ON question TYPE float;
DEFINE FIELD distractors ON question TYPE array;
DEFINE FIELD context_wrap ON question TYPE option<string>;  -- LLM word problem
DEFINE FIELD embedding   ON question TYPE option<array>;    -- for similarity search
DEFINE FIELD created_at  ON question TYPE datetime DEFAULT time::now();

-- Students
DEFINE TABLE student SCHEMAFULL;
DEFINE FIELD name       ON student TYPE string;
DEFINE FIELD email      ON student TYPE string;
DEFINE FIELD created_at ON student TYPE datetime DEFAULT time::now();

-- BKT Mastery State (per student per KC)
DEFINE TABLE mastery SCHEMAFULL;
DEFINE FIELD student_id ON mastery TYPE record<student>;
DEFINE FIELD kc_id      ON mastery TYPE record<kc>;
DEFINE FIELD p_mastery  ON mastery TYPE float DEFAULT 0.1;
DEFINE FIELD p_learn    ON mastery TYPE float DEFAULT 0.2;
DEFINE FIELD p_slip     ON mastery TYPE float DEFAULT 0.1;
DEFINE FIELD p_guess    ON mastery TYPE float DEFAULT 0.2;
DEFINE FIELD attempt_count ON mastery TYPE int DEFAULT 0;
DEFINE FIELD updated_at ON mastery TYPE datetime DEFAULT time::now();

-- Response Log
DEFINE TABLE response SCHEMAFULL;
DEFINE FIELD student_id  ON response TYPE record<student>;
DEFINE FIELD question_id ON response TYPE record<question>;
DEFINE FIELD kc_id       ON response TYPE record<kc>;
DEFINE FIELD answer_given ON response TYPE float;
DEFINE FIELD is_correct  ON response TYPE bool;
DEFINE FIELD time_taken_ms ON response TYPE int;
DEFINE FIELD created_at  ON response TYPE datetime DEFAULT time::now();

-- Indexes
DEFINE INDEX idx_mastery_student_kc ON mastery FIELDS student_id, kc_id UNIQUE;
DEFINE INDEX idx_question_kc_diff   ON question FIELDS kc_id, difficulty;
DEFINE INDEX idx_response_student   ON response FIELDS student_id;
```

### 5.3 Chạy migration

```rust
// src/db/mod.rs
use anyhow::Result;
use crate::db::client::Db;

pub async fn run_migrations(db: &Db) -> Result<()> {
    let schema = include_str!("../../migrations/001_schema.surql");
    db.query(schema).await?;
    println!("✅ Migrations applied");
    Ok(())
}
```

---

## 6. Knowledge Component Graph

### 6.1 Domain types — `src/domain/kc.rs`

```rust
use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Kc {
    pub id: Option<Thing>,
    pub name: String,
    pub description: String,
    pub bloom_level: BloomLevel,
    pub difficulty_min: u8,
    pub difficulty_max: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
pub enum BloomLevel {
    Remember,
    Understand,
    Apply,
    Analyze,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct KcEdge {
    #[serde(rename = "in")]
    pub from: Thing,
    #[serde(rename = "out")]
    pub to: Thing,
}
```

### 6.2 Repository — `src/db/kc_repo.rs`

```rust
use anyhow::Result;
use crate::db::client::Db;
use crate::domain::kc::{Kc, KcEdge};
use surrealdb::sql::Thing;

pub struct KcRepo<'a> {
    db: &'a Db,
}

impl<'a> KcRepo<'a> {
    pub fn new(db: &'a Db) -> Self { Self { db } }

    pub async fn create(&self, kc: &Kc) -> Result<Kc> {
        let created: Option<Kc> = self.db
            .create("kc")
            .content(kc)
            .await?;
        Ok(created.unwrap())
    }

    pub async fn add_prerequisite(&self, from: &Thing, to: &Thing) -> Result<()> {
        // Graph edge: from ->prerequisite_of-> to
        let query = format!(
            "RELATE {}->prerequisite_of->{}",
            from, to
        );
        self.db.query(query).await?;
        Ok(())
    }

    /// Lấy tất cả KC mà một KC phụ thuộc vào (toàn bộ prerequisite chain)
    pub async fn get_prerequisites_deep(&self, kc_id: &Thing) -> Result<Vec<Kc>> {
        let query = format!(
            "SELECT <-prerequisite_of<-kc.* FROM {} FETCH 5",
            kc_id
        );
        let mut res = self.db.query(query).await?;
        let kcs: Vec<Kc> = res.take(0)?;
        Ok(kcs)
    }
}
```

### 6.3 Seed dữ liệu KC mẫu

```rust
// src/db/seed.rs
use crate::db::client::Db;
use crate::domain::kc::{BloomLevel, Kc};
use crate::db::kc_repo::KcRepo;
use anyhow::Result;

pub async fn seed_kcs(db: &Db) -> Result<()> {
    let repo = KcRepo::new(db);

    let arithmetic = repo.create(&Kc {
        id: None,
        name: "arithmetic_ops".into(),
        description: "Phép tính cơ bản: +, -, ×, ÷".into(),
        bloom_level: BloomLevel::Remember,
        difficulty_min: 1,
        difficulty_max: 2,
    }).await?;

    let linear_eq = repo.create(&Kc {
        id: None,
        name: "linear_equation_1var".into(),
        description: "Giải phương trình bậc nhất một ẩn".into(),
        bloom_level: BloomLevel::Apply,
        difficulty_min: 2,
        difficulty_max: 4,
    }).await?;

    // arithmetic là prerequisite của linear_eq
    if let (Some(a_id), Some(l_id)) = (&arithmetic.id, &linear_eq.id) {
        repo.add_prerequisite(a_id, l_id).await?;
    }

    println!("✅ Seeded KCs");
    Ok(())
}
```

---

## 7. Template Engine

### 7.1 Domain — `src/domain/template.rs`

```rust
use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ParamConstraint {
    pub min: f64,
    pub max: f64,
    pub integer_only: bool,
    pub exclude_zero: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QuestionTemplate {
    pub id: Option<Thing>,
    pub kc_id: Thing,
    pub difficulty: u8,
    pub bloom_level: String,
    pub stem_template: String,          // "Giải {{a}}x + {{b}} = {{c}}"
    pub param_schema: HashMap<String, ParamConstraint>,
    pub solution_expr: String,          // "( c - b ) / a"
    pub error_taxonomy: Vec<String>,    // ["sign_flip", "arithmetic_slip", ...]
    pub active: bool,
}
```

### 7.2 Template renderer — `src/engine/generator.rs`

```rust
use minijinja::Environment;
use std::collections::HashMap;
use anyhow::Result;

pub fn render_stem(template: &str, params: &HashMap<String, f64>) -> Result<String> {
    let mut env = Environment::new();
    env.add_template("stem", template)?;

    let tmpl = env.get_template("stem")?;
    let ctx = minijinja::Value::from_serialize(params);
    Ok(tmpl.render(ctx)?)
}

/// Evaluate solution expression
/// Hỗ trợ các biểu thức đơn giản: (c - b) / a
pub fn eval_solution(expr: &str, params: &HashMap<String, f64>) -> Result<f64> {
    // Thay thế biến rồi evaluate
    let mut expression = expr.to_string();
    for (k, v) in params {
        expression = expression.replace(k.as_str(), &v.to_string());
    }
    // Dùng meval để eval biểu thức toán học
    Ok(meval::eval_str(&expression)?)
}
```

> **Lưu ý:** Thêm `meval = "0.2"` vào `Cargo.toml` để evaluate biểu thức toán học dạng string.

---

## 8. Parameter Sampler

### 8.1 `src/engine/sampler.rs`

```rust
use rand::Rng;
use std::collections::HashMap;
use anyhow::{bail, Result};
use crate::domain::template::{ParamConstraint, QuestionTemplate};

const MAX_RETRY: usize = 100;
const DIFFICULTY_TOLERANCE: f64 = 0.5;

pub struct SampledParams {
    pub params: HashMap<String, f64>,
    pub estimated_difficulty: f64,
}

pub fn sample_params(template: &QuestionTemplate, target_difficulty: u8) -> Result<SampledParams> {
    let mut rng = rand::thread_rng();

    for _ in 0..MAX_RETRY {
        let mut params = HashMap::new();

        for (name, constraint) in &template.param_schema {
            let value = sample_one(&mut rng, constraint);
            params.insert(name.clone(), value);
        }

        if !validate_mathematical(&params, template) {
            continue;
        }

        let estimated = estimate_difficulty(&params);
        if (estimated - target_difficulty as f64).abs() <= DIFFICULTY_TOLERANCE {
            return Ok(SampledParams { params, estimated_difficulty: estimated });
        }
    }

    bail!("Could not sample valid params for template {} with difficulty {}", 
          template.id.as_ref().map(|t| t.to_string()).unwrap_or_default(), 
          target_difficulty)
}

fn sample_one(rng: &mut impl Rng, c: &ParamConstraint) -> f64 {
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

/// Heuristic ước lượng độ khó dựa trên magnitude và sign complexity
fn estimate_difficulty(params: &HashMap<String, f64>) -> f64 {
    let magnitude_score: f64 = params.values()
        .map(|v| v.abs())
        .sum::<f64>() / params.len() as f64;

    let sign_complexity: f64 = params.values()
        .filter(|&&v| v < 0.0)
        .count() as f64;

    let has_decimal: f64 = params.values()
        .filter(|&&v| v.fract() != 0.0)
        .count() as f64 * 1.5;

    // Normalize thành scale 1-5
    let raw = 1.0 + (magnitude_score / 10.0) + sign_complexity * 0.5 + has_decimal;
    raw.clamp(1.0, 5.0)
}

fn validate_mathematical(params: &HashMap<String, f64>, template: &QuestionTemplate) -> bool {
    // Kiểm tra chia cho 0
    if let Some(&a) = params.get("a") {
        if a == 0.0 { return false; }
    }
    // Kiểm tra nghiệm nguyên (nếu template yêu cầu)
    // Có thể mở rộng thêm logic tại đây
    true
}
```

---

## 9. Distractor Generator

### 9.1 `src/engine/distractor.rs`

```rust
use rand::Rng;
use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct Distractor {
    pub value: f64,
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
            "sign_flip" => {
                // Học sinh quên đổi dấu khi chuyển vế
                params.get("b").map(|b| correct + 2.0 * b)
            }
            "arithmetic_slip" => {
                let delta = *rng.sample(
                    &rand::distributions::Slice::new(&[-2.0f64, -1.0, 1.0, 2.0]).unwrap()
                );
                Some(correct + delta)
            }
            "forgot_divide" => {
                // Học sinh quên bước chia cuối cùng
                params.get("a").map(|a| correct * a)
            }
            "wrong_order" => {
                // b + c thay vì c - b
                match (params.get("b"), params.get("c")) {
                    (Some(b), Some(c)) => params.get("a").map(|a| (b + c) / a),
                    _ => None,
                }
            }
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

    // Nếu chưa đủ n, sinh thêm bằng noise
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
    val != correct
        && val.is_finite()
        && !existing.iter().any(|d| (d.value - val).abs() < 0.01)
}

fn round2(v: f64) -> f64 {
    (v * 100.0).round() / 100.0
}
```

---

## 10. Bayesian Knowledge Tracing

### 10.1 `src/engine/bkt.rs`

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BktState {
    pub p_mastery: f64,
    pub p_learn: f64,
    pub p_slip: f64,
    pub p_guess: f64,
}

impl Default for BktState {
    fn default() -> Self {
        Self {
            p_mastery: 0.1,
            p_learn: 0.2,
            p_slip: 0.1,
            p_guess: 0.2,
        }
    }
}

impl BktState {
    /// Cập nhật BKT state sau một câu trả lời
    pub fn update(&self, is_correct: bool) -> Self {
        let p = self.p_mastery;

        // Bước 1: Bayes update dựa trên observation
        let p_obs_given_known = if is_correct { 1.0 - self.p_slip } else { self.p_slip };
        let p_obs_given_not   = if is_correct { self.p_guess } else { 1.0 - self.p_guess };

        let p_obs = p_obs_given_known * p + p_obs_given_not * (1.0 - p);

        let p_known_given_obs = if p_obs > 0.0 {
            (p_obs_given_known * p) / p_obs
        } else {
            p
        };

        // Bước 2: Learning transition
        let p_new = p_known_given_obs + (1.0 - p_known_given_obs) * self.p_learn;

        Self {
            p_mastery: p_new.clamp(0.0, 1.0),
            ..self.clone()
        }
    }

    pub fn is_mastered(&self) -> bool {
        self.p_mastery >= 0.95
    }

    pub fn difficulty_target(&self) -> u8 {
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
    fn test_mastery_decreases_on_wrong() {
        let state = BktState { p_mastery: 0.6, ..Default::default() };
        let after = state.update(false);
        assert!(after.p_mastery < state.p_mastery);
    }

    #[test]
    fn test_five_correct_answers_near_mastery() {
        let mut state = BktState::default();
        for _ in 0..5 { state = state.update(true); }
        assert!(state.p_mastery > 0.7);
    }
}
```

---

## 11. Adaptive Question Selector

### 11.1 `src/adaptive/selector.rs`

```rust
use anyhow::Result;
use surrealdb::sql::Thing;
use crate::db::client::Db;
use crate::domain::question::Question;
use crate::engine::bkt::BktState;

pub struct AdaptiveSelector<'a> {
    db: &'a Db,
}

impl<'a> AdaptiveSelector<'a> {
    pub fn new(db: &'a Db) -> Self { Self { db } }

    pub async fn next_question(
        &self,
        student_id: &Thing,
        kc_id: &Thing,
        bkt: &BktState,
    ) -> Result<Option<Question>> {
        let target_diff = bkt.difficulty_target();

        // Lấy danh sách câu hỏi chưa làm gần đây + phù hợp độ khó
        let query = r#"
            SELECT q.* FROM question AS q
            WHERE q.kc_id = $kc_id
            AND q.difficulty = $diff
            AND q.id NOT IN (
                SELECT question_id FROM response
                WHERE student_id = $student_id
                ORDER BY created_at DESC
                LIMIT 20
            )
            ORDER BY rand()
            LIMIT 1
        "#;

        let mut res = self.db.query(query)
            .bind(("kc_id", kc_id.clone()))
            .bind(("diff", target_diff))
            .bind(("student_id", student_id.clone()))
            .await?;

        let questions: Vec<Question> = res.take(0)?;
        Ok(questions.into_iter().next())
    }
}
```

---

## 12. LLM Augmentation với Anthropic API

### 12.1 `src/llm/anthropic.rs`

```rust
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
        Self { http: Client::new(), api_key }
    }

    /// Bọc câu hỏi toán thuần túy thành bài toán ngữ cảnh thực tế
    pub async fn wrap_word_problem(
        &self,
        bare_stem: &str,
        answer: f64,
        params: &HashMap<String, f64>,
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
- Đảm bảo đáp án vẫn là {answer}"#
        );

        let req = AnthropicRequest {
            model: MODEL.into(),
            max_tokens: 300,
            messages: vec![Message { role: "user".into(), content: prompt }],
        };

        let resp = self.http.post(ANTHROPIC_API)
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .json(&req)
            .send().await?
            .json::<AnthropicResponse>().await?;

        let text = resp.content.iter()
            .filter(|b| b.block_type == "text")
            .filter_map(|b| b.text.as_ref())
            .cloned()
            .collect::<Vec<_>>()
            .join("");

        Ok(text.trim().to_string())
    }
}
```

---

## 13. HTTP API Layer

### 13.1 Routes — `src/api/routes.rs`

```rust
use axum::{
    Router,
    routing::{get, post},
};
use std::sync::Arc;
use crate::db::client::Db;

pub struct AppState {
    pub db: Db,
    pub anthropic_key: String,
}

pub fn create_router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/health",                   get(handlers::health))
        .route("/students",                 post(handlers::create_student))
        .route("/students/:id/next",        get(handlers::next_question))
        .route("/students/:id/answer",      post(handlers::submit_answer))
        .route("/students/:id/mastery/:kc", get(handlers::get_mastery))
        .route("/questions/generate",       post(handlers::generate_questions))
        .with_state(state)
}
```

### 13.2 Handlers — `src/api/handlers.rs`

```rust
use axum::{
    extract::{Path, State, Json},
    http::StatusCode,
    response::IntoResponse,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use crate::api::routes::AppState;
use crate::adaptive::selector::AdaptiveSelector;
use crate::engine::bkt::BktState;

#[derive(Serialize)]
pub struct HealthResponse { status: &'static str }

pub async fn health() -> Json<HealthResponse> {
    Json(HealthResponse { status: "ok" })
}

#[derive(Deserialize)]
pub struct AnswerPayload {
    pub question_id: String,
    pub kc_id: String,
    pub answer_given: f64,
    pub time_taken_ms: u32,
}

#[derive(Serialize)]
pub struct AnswerResult {
    pub is_correct: bool,
    pub correct_answer: f64,
    pub p_mastery_new: f64,
    pub is_mastered: bool,
    pub feedback: String,
}

pub async fn submit_answer(
    Path(student_id): Path<String>,
    State(state): State<Arc<AppState>>,
    Json(payload): Json<AnswerPayload>,
) -> impl IntoResponse {
    // 1. Lấy question để biết đáp án đúng
    // 2. So sánh answer_given với correct answer
    // 3. Lấy BKT state hiện tại từ DB
    // 4. Update BKT
    // 5. Lưu response log
    // 6. Trả về kết quả
    
    // (Simplified demo — implement full logic tương tự)
    Json(AnswerResult {
        is_correct: true,
        correct_answer: 3.0,
        p_mastery_new: 0.65,
        is_mastered: false,
        feedback: "Chính xác! Tiếp tục phát huy.".into(),
    })
}

pub async fn next_question(
    Path(student_id): Path<String>,
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    // Lấy KC hiện tại của student
    // Lấy BKT state
    // Dùng AdaptiveSelector để chọn câu
    StatusCode::OK
}
```

---

## 14. Chạy toàn bộ pipeline

### 14.1 `src/main.rs`

```rust
mod config;
mod db;
mod domain;
mod engine;
mod adaptive;
mod llm;
mod api;

use anyhow::Result;
use std::sync::Arc;
use dotenvy::dotenv;
use std::env;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

#[tokio::main]
async fn main() -> Result<()> {
    dotenv().ok();

    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(
            env::var("RUST_LOG").unwrap_or_else(|_| "info".into())
        ))
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Kết nối SurrealDB
    let db = db::client::connect(
        &env::var("SURREAL_URL")?,
        &env::var("SURREAL_USER")?,
        &env::var("SURREAL_PASS")?,
        &env::var("SURREAL_NS")?,
        &env::var("SURREAL_DB")?,
    ).await?;

    // Migration + seed
    db::run_migrations(&db).await?;
    db::seed::seed_kcs(&db).await?;

    let state = Arc::new(api::routes::AppState {
        db,
        anthropic_key: env::var("ANTHROPIC_API_KEY")?,
    });

    let router = api::routes::create_router(state);

    let addr = format!(
        "{}:{}",
        env::var("HOST").unwrap_or_else(|_| "127.0.0.1".into()),
        env::var("PORT").unwrap_or_else(|_| "3000".into()),
    );

    tracing::info!("🚀 Server listening on http://{}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    axum::serve(listener, router).await?;

    Ok(())
}
```

### 14.2 Chạy development

```bash
# Terminal 1: SurrealDB
surreal start --log debug --user root --pass root memory

# Terminal 2: Server
RUST_LOG=debug cargo run

# Test health
curl http://localhost:3000/health
# → {"status":"ok"}
```

### 14.3 Chạy generation pipeline thủ công

```bash
# Tạo câu hỏi từ một template (ví dụ bằng curl)
curl -X POST http://localhost:3000/questions/generate \
  -H "Content-Type: application/json" \
  -d '{
    "kc_id": "kc:linear_equation_1var",
    "difficulty": 3,
    "count": 10,
    "use_llm_wrap": true,
    "domain": "mua sắm"
  }'
```

---

## 15. Testing

### 15.1 Unit test BKT

```bash
cargo test bkt
```

### 15.2 Integration test với SurrealDB in-memory

```rust
#[cfg(test)]
mod integration_tests {
    use super::*;
    use surrealdb::engine::local::Mem;
    use surrealdb::Surreal;

    #[tokio::test]
    async fn test_full_generation_pipeline() {
        let db = Surreal::new::<Mem>(()).await.unwrap();
        db.use_ns("test").use_db("test").await.unwrap();
        db::run_migrations(&db).await.unwrap();

        // Tạo KC
        // Tạo Template
        // Chạy sampler
        // Kiểm tra output question hợp lệ
        assert!(true); // placeholder
    }
}
```

### 15.3 Load test pipeline

```bash
# Cài hey
cargo install hey  # hoặc brew install hey

# 100 concurrent requests
hey -n 1000 -c 100 http://localhost:3000/health
```

---

## Checklist hoàn chỉnh

- [ ] SurrealDB chạy, schema applied
- [ ] KC seeded với quan hệ prerequisite
- [ ] Ít nhất 2 template per KC
- [ ] Sampler sinh được params hợp lệ
- [ ] Distractor generator sinh 3 sai đáp án per câu
- [ ] BKT update đúng chiều (correct → tăng, wrong → giảm)
- [ ] Adaptive selector chọn đúng difficulty dựa trên mastery
- [ ] LLM wrap hoạt động (có ANTHROPIC_API_KEY)
- [ ] API `/students/:id/next` và `/answer` hoạt động end-to-end
- [ ] Unit tests pass

---

## Tài liệu tham khảo

- [SurrealDB Rust SDK](https://surrealdb.com/docs/integration/libraries/rust)
- [Axum Documentation](https://docs.rs/axum)
- [Corbett, Anderson (1994) — Knowledge Tracing paper gốc](https://dl.acm.org/doi/10.1007/BF01099821)
- [pyBKT — reference implementation](https://github.com/CAHLR/pyBKT)
- [Minijinja templating](https://docs.rs/minijinja)
