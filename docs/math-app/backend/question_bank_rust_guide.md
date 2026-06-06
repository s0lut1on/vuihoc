# Hướng Dẫn Triển Khai Question Bank – Tích Hợp Math App

> **Stack:** Rust · PostgreSQL · sqlx · Axum · Tokio · minijinja · meval  
> **Tích hợp với:** math-app (microservices: Flutter frontend + Rust backend)  
> **Mức độ:** Intermediate  
> **Thời gian ước tính:** 3–5 ngày

---

## Mục lục

1. [Tổng quan tích hợp](#1-tổng-quan-tích-hợp)
2. [Kiến trúc hệ thống Question Bank](#2-kiến-trúc-hệ-thống-question-bank)
3. [Chuẩn bị môi trường](#3-chuẩn-bị-môi-trường)
4. [Khởi tạo crate mới trong workspace](#4-khởi-tạo-crate-mới-trong-workspace)
5. [PostgreSQL Schema & Migrations](#5-postgresql-schema--migrations)
6. [Knowledge Component Graph](#6-knowledge-component-graph)
7. [Template Engine](#7-template-engine)
8. [Parameter Sampler](#8-parameter-sampler)
9. [Distractor Generator](#9-distractor-generator)
10. [Bayesian Knowledge Tracing](#10-bayesian-knowledge-tracing)
11. [Adaptive Question Selector](#11-adaptive-question-selector)
12. [HTTP API Layer (Axum + utoipa)](#12-http-api-layer-axum--utoipa)
13. [Tích hợp với Content Service](#13-tích-hợp-với-content-service)
14. [Chạy toàn bộ pipeline](#14-chạy-toàn-bộ-pipeline)
15. [Testing](#15-testing)

---

## 1. Tổng quan tích hợp

### 1.1 So sánh với hệ thống hiện có

| Khía cạnh | Hệ thống hiện có | Question Bank (bổ sung) |
|---|---|---|
| **Database** | PostgreSQL + sqlx | Tiếp tục dùng PostgreSQL + sqlx |
| **Architecture** | Microservices (workspace crates) | Thêm crate `question_bank` vào workspace |
| **API docs** | utoipa + Swagger UI | Theo cùng pattern |
| **Response format** | `shared::ApiResponse<T>` | Dùng chung pattern này |
| **HTTP client** | reqwest (có sẵn) | Dùng reqwest cho Anthropic API |
| **Templating** | Chưa có | Thêm `minijinja` + `meval` |
| **Math/Random** | Chưa có | Thêm `rand` (đã có) + `statrs` |

### 1.2 Vị trí trong hệ thống

```
math-app/
├── backend/
│   ├── Cargo.toml              ← workspace root
│   ├── shared/                 ← ApiResponse, HealthResponse
│   ├── content/                ← curriculum, lessons (đã có)
│   ├── question_bank/          ← [MỚI] question bank service
│   │   ├── Cargo.toml
│   │   ├── src/
│   │   │   ├── main.rs
│   │   │   ├── handlers.rs
│   │   │   ├── models.rs
│   │   │   ├── db.rs
│   │   │   ├── engine/
│   │   │   │   ├── mod.rs
│   │   │   │   ├── sampler.rs
│   │   │   │   ├── generator.rs
│   │   │   │   ├── distractor.rs
│   │   │   │   └── bkt.rs
│   │   │   └── llm/
│   │   │       └── anthropic.rs
│   │   └── migrations/
│   │       └── 001_question_bank.sql
│   ├── auth/
│   ├── user/
│   ├── progress/               ← học sinh + bkt mastery
│   └── ...
└── frontend/
    └── lib/
        └── services/
            └── question_api.dart  ← [MỚI] gọi question bank API
```

**Luồng dữ liệu:**
```
Author định nghĩa KC + Template → lưu vào question_bank DB
    → Generator sinh Question instances
        → Bank lưu vào PostgreSQL
            → Adaptive Selector chọn câu phù hợp student
                → BKT cập nhật mastery (qua progress service)
                    → Frontend hiển thị câu hỏi
```

---

## 2. Kiến trúc hệ thống Question Bank

```
┌─────────────────────────────────────────────────────────────┐
│           HTTP API (Axum) + utoipa/Swagger UI                │
│    /questions/next  /answers/submit  /students/:id/mastery   │
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
         │           PostgreSQL              │
         │  kc | template | question |        │
         │  student | response | mastery      │
         └───────────────────────────────────┘
                         │
         ┌───────────────▼───────────────────┐
         │        Anthropic API (reqwest)   │
         │   (Word problem wrapper / LLM)   │
         └───────────────────────────────────┘
```

---

## 3. Chuẩn bị môi trường

### 3.1 Kiểm tra Rust version

```bash
cd math-app/backend
rustc --version   # cần 1.78+
cargo --version
```

### 3.2 Biến môi trường

Thêm vào `.env` (hoặc `backend/question_bank/.env`):

```env
DATABASE_URL=postgres://qb_user:qb_pass@localhost:5432/qb_db
ANTHROPIC_API_KEY=sk-ant-...

HOST=0.0.0.0
PORT=3000
```

**Trong docker-compose.yml** (bổ sung service):

```yaml
  question-bank-service:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        SERVICE_NAME: question_bank
    environment:
      - PORT=3000
      - DATABASE_URL=postgres://qb_user:qb_pass@qb-db:5432/qb_db
      - REDIS_URL=redis://redis:6379
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
    depends_on:
      - qb-db
      - redis
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.question-bank.rule=PathPrefix(`/api/questions`)"
    restart: unless-stopped

  qb-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: qb_db
      POSTGRES_USER: qb_user
      POSTGRES_PASSWORD: qb_pass
    volumes:
      - qb_db_data:/var/lib/postgresql/data
    restart: unless-stopped
```

Và thêm volume:
```yaml
volumes:
  qb_db_data:
```

---

## 4. Khởi tạo crate mới trong workspace

### 4.1 Thêm vào workspace root

```toml
# backend/Cargo.toml
[workspace]
resolver = "2"
members = ["shared", "auth", "user", "content", "progress", "notification", "media", "question_bank"]

[workspace.dependencies]
# ... giữ nguyên dependencies hiện có ...
# Thêm mới:
minijinja = "2"
meval = "0.2"
statrs = "0.16"
```

### 4.2 Tạo crate

```bash
cd math-app/backend
cargo new --name question_bank question_bank
```

### 4.3 `backend/question_bank/Cargo.toml`

```toml
[package]
name = "question_bank"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = { workspace = true }
tokio = { workspace = true }
tower-http = { workspace = true }
serde = { workspace = true }
serde_json = { workspace = true }
tracing = { workspace = true }
tracing-subscriber = { workspace = true }
sqlx = { workspace = true }
utoipa = { workspace = true }
utoipa-swagger-ui = { workspace = true }
chrono = { workspace = true }
uuid = { workspace = true }
anyhow = { workspace = true }
thiserror = { workspace = true }
reqwest = { workspace = true }

# New dependencies
minijinja = { workspace = true }
meval = { workspace = true }
statrs = { workspace = true }
rand = "0.8"

shared = { path = "../shared" }

[dev-dependencies]
reqwest = { workspace = true }
```

### 4.4 Cấu trúc thư mục

```
question_bank/
├── Cargo.toml
├── migrations/
│   └── 001_question_bank.sql
└── src/
    ├── main.rs
    ├── handlers.rs
    ├── models.rs
    ├── db.rs
    ├── engine/
    │   ├── mod.rs
    │   ├── sampler.rs
    │   ├── generator.rs
    │   ├── distractor.rs
    │   └── bkt.rs
    └── llm/
        └── anthropic.rs
```

---

## 5. PostgreSQL Schema & Migrations

### 5.1 `backend/question_bank/migrations/001_question_bank.sql`

```sql
-- Knowledge Components
CREATE TABLE kc (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    bloom_level VARCHAR(20) CHECK (bloom_level IN ('remember', 'understand', 'apply', 'analyze')),
    difficulty_min INT DEFAULT 1,
    difficulty_max INT DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Prerequisite relationships (DAG)
CREATE TABLE kc_prerequisite (
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    prerequisite_kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    PRIMARY KEY (kc_id, prerequisite_kc_id),
    CHECK (kc_id != prerequisite_kc_id)
);

-- Question Templates
CREATE TABLE template (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    difficulty INT NOT NULL CHECK (difficulty BETWEEN 1 AND 5),
    bloom_level VARCHAR(20),
    stem_template TEXT NOT NULL,  -- Jinja2-like: "Giải {{a}}x + {{b}} = {{c}}"
    param_schema JSONB NOT NULL,  -- {"a": {"min": 1, "max": 9, "integer": true}}
    solution_expr TEXT NOT NULL,  -- e.g. "(c - b) / a"
    error_taxonomy JSONB DEFAULT '[]', -- ["sign_flip", "arithmetic_slip"]
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Generated Questions
CREATE TABLE question (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID REFERENCES template(id) ON DELETE CASCADE,
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    difficulty INT NOT NULL,
    stem TEXT NOT NULL,
    params JSONB NOT NULL,
    answer FLOAT NOT NULL,
    distractors JSONB NOT NULL,     -- [2.5, 4.0, 7.0]
    context_wrap TEXT,              -- LLM word problem
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Students (reference từ user service)
CREATE TABLE student (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,          -- FK tới user_service
    name VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- BKT Mastery State (per student per KC)
CREATE TABLE mastery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES student(id) ON DELETE CASCADE,
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    p_mastery FLOAT DEFAULT 0.1,
    p_learn FLOAT DEFAULT 0.2,
    p_slip FLOAT DEFAULT 0.1,
    p_guess FLOAT DEFAULT 0.2,
    attempt_count INT DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (student_id, kc_id)
);

-- Response Log
CREATE TABLE response (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES student(id) ON DELETE CASCADE,
    question_id UUID REFERENCES question(id) ON DELETE CASCADE,
    kc_id UUID REFERENCES kc(id) ON DELETE CASCADE,
    answer_given FLOAT,
    is_correct BOOLEAN,
    time_taken_ms INT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_question_kc_diff ON question(kc_id, difficulty);
CREATE INDEX idx_mastery_student_kc ON mastery(student_id, kc_id);
CREATE INDEX idx_response_student ON response(student_id);
CREATE INDEX idx_response_question ON response(question_id);
```

### 5.2 `src/db.rs` – Database client

```rust
use sqlx::PgPool;
use anyhow::Result;

#[derive(Clone)]
pub struct Db(PgPool);

impl Db {
    pub async fn connect(url: &str) -> Result<Self> {
        let pool = PgPool::connect(url).await?;
        Ok(Self(pool))
    }

    pub fn pool(&self) -> &PgPool {
        &self.0
    }

    pub async fn run_migrations(&self) -> Result<()> {
        let migration_dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .join("migrations");
        let migrator = sqlx::migrate::Migrator::new(migration_dir).await?;
        migrator.run(&self.0).await?;
        Ok(())
    }
}
```

---

## 6. Knowledge Component Graph

### 6.1 Domain types – `src/models.rs`

```rust
use serde::{Deserialize, Serialize};
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow, ToSchema)]
pub struct Kc {
    pub id: Option<Uuid>,
    pub name: String,
    pub description: String,
    pub bloom_level: BloomLevel,
    pub difficulty_min: i32,
    pub difficulty_max: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, ToSchema)]
#[serde(rename_all = "lowercase")]
pub enum BloomLevel {
    Remember,
    Understand,
    Apply,
    Analyze,
}

impl sqlx::Type<sqlx::Postgres> for BloomLevel {
    fn type_info() -> sqlx::postgres::PgTypeInfo {
        sqlx::postgres::PgTypeInfo::with_name("VARCHAR")
    }
}

impl<'r> sqlx::Decode<'r, sqlx::Postgres> for BloomLevel {
    fn decode(value: sqlx::postgres::PgValueRef<'r>) -> Result<Self, sqlx::error::BoxDynError> {
        let s: String = sqlx::Decode::decode(value)?;
        Ok(match s.as_str() {
            "remember" => BloomLevel::Remember,
            "understand" => BloomLevel::Understand,
            "apply" => BloomLevel::Apply,
            "analyze" => BloomLevel::Analyze,
            _ => BloomLevel::Remember,
        })
    }
}

#[derive(Debug, Serialize, Deserialize, FromRow)]
pub struct KcEdge {
    pub kc_id: Uuid,
    pub prerequisite_kc_id: Uuid,
}
```

### 6.2 Seed dữ liệu mẫu

```rust
// Trong handlers hoặc migration seed
use sqlx::PgPool;
use anyhow::Result;

pub async fn seed_kcs(pool: &PgPool) -> Result<()> {
    let arithmetic = sqlx::query_as::<_, Kc>(
        r#"INSERT INTO kc (name, description, bloom_level, difficulty_min, difficulty_max)
           VALUES ('arithmetic_ops', 'Phép tính cơ bản: +, -, ×, ÷', 'remember', 1, 2)
           RETURNING *"#
    )
    .fetch_one(pool)
    .await?;

    let linear_eq = sqlx::query_as::<_, Kc>(
        r#"INSERT INTO kc (name, description, bloom_level, difficulty_min, difficulty_max)
           VALUES ('linear_equation_1var', 'Giải phương trình bậc nhất một ẩn', 'apply', 2, 4)
           RETURNING *"#
    )
    .fetch_one(pool)
    .await?;

    // arithmetic là prerequisite của linear_eq
    if let (Some(a_id), Some(l_id)) = (arithmetic.id, linear_eq.id) {
        sqlx::query(
            "INSERT INTO kc_prerequisite (kc_id, prerequisite_kc_id) VALUES ($1, $2)"
        )
        .bind(a_id)
        .bind(l_id)
        .execute(pool)
        .await?;
    }

    Ok(())
}
```

---

## 7. Template Engine

### 7.1 Domain types – `src/models.rs`

```rust
use std::collections::HashMap;

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
    pub stem_template: String,      // "Giải {{a}}x + {{b}} = {{c}}"
    pub param_schema: serde_json::Value,  // JSON object
    pub solution_expr: String,      // "( c - b ) / a"
    pub error_taxonomy: serde_json::Value, // JSON array
    pub active: bool,
}
```

### 7.2 Template renderer – `src/engine/generator.rs`

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
pub fn eval_solution(expr: &str, params: &HashMap<String, f64>) -> Result<f64> {
    let mut expression = expr.to_string();
    for (k, v) in params {
        expression = expression.replace(k.as_str(), &v.to_string());
    }
    Ok(meval::eval_str(&expression)?)
}
```

---

## 8. Parameter Sampler

### 8.1 `src/engine/sampler.rs`

```rust
use rand::Rng;
use std::collections::HashMap;
use anyhow::{bail, Result};
use crate::models::{ParamConstraint, QuestionTemplate};

const MAX_RETRY: usize = 100;
const DIFFICULTY_TOLERANCE: f64 = 0.5;

#[derive(Debug, Clone)]
pub struct SampledParams {
    pub params: HashMap<String, f64>,
    pub estimated_difficulty: f64,
}

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
            return Ok(SampledParams { params, estimated_difficulty: estimated });
        }
    }

    bail!("Could not sample valid params with difficulty {}", target_difficulty)
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
    let magnitude_score: f64 = params.values()
        .map(|v| v.abs())
        .sum::<f64>() / params.len().max(1) as f64;

    let sign_complexity: f64 = params.values()
        .filter(|&&v| v < 0.0)
        .count() as f64;

    let has_decimal: f64 = params.values()
        .filter(|&&v| v.fract() != 0.0)
        .count() as f64 * 1.5;

    let raw = 1.0 + (magnitude_score / 10.0) + sign_complexity * 0.5 + has_decimal;
    raw.clamp(1.0, 5.0)
}

fn validate_mathematical(params: &HashMap<String, f64>) -> bool {
    if let Some(&a) = params.get("a") {
        if a == 0.0 { return false; }
    }
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
                params.get("b").map(|b| correct + 2.0 * b)
            }
            "arithmetic_slip" => {
                let delta = rng.gen_range(-2..=2) as f64;
                Some(correct + delta)
            }
            "forgot_divide" => {
                params.get("a").map(|a| correct * a)
            }
            "wrong_order" => {
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
use sqlx::FromRow;
use utoipa::ToSchema;
use uuid::Uuid;

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
    /// Cập nhật BKT state sau một câu trả lời
    pub fn update(&self, is_correct: bool) -> Self {
        let p = self.p_mastery;

        let p_obs_given_known = if is_correct { 1.0 - self.p_slip } else { self.p_slip };
        let p_obs_given_not   = if is_correct { self.p_guess } else { 1.0 - self.p_guess };

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
        for _ in 0..5 { state = state.update(true); }
        assert!(state.p_mastery > 0.7);
    }
}
```

---

## 11. Adaptive Question Selector

### 11.1 `src/engine/mod.rs`

```rust
pub mod sampler;
pub mod generator;
pub mod distractor;
pub mod bkt;

use sqlx::PgPool;
use anyhow::Result;
use uuid::Uuid;
use crate::models::Question;
use crate::engine::bkt::BktState;

pub struct AdaptiveSelector<'a> {
    pool: &'a PgPool,
}

impl<'a> AdaptiveSelector<'a> {
    pub fn new(pool: &'a PgPool) -> Self {
        Self { pool }
    }

    pub async fn next_question(
        &self,
        student_id: Uuid,
        kc_id: Uuid,
        bkt: &BktState,
    ) -> Result<Option<Question>> {
        let target_diff = bkt.difficulty_target();

        let question = sqlx::query_as::<_, Question>(
            r#"
            SELECT q.* FROM question q
            WHERE q.kc_id = $1
            AND q.difficulty = $2
            AND q.id NOT IN (
                SELECT question_id FROM response
                WHERE student_id = $3
                ORDER BY created_at DESC
                LIMIT 20
            )
            ORDER BY random()
            LIMIT 1
            "#
        )
        .bind(kc_id)
        .bind(target_diff)
        .bind(student_id)
        .fetch_optional(self.pool)
        .await?;

        Ok(question)
    }
}
```

---

## 12. HTTP API Layer (Axum + utoipa)

### 12.1 `src/models.rs` – API types

```rust
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use chrono::{DateTime, Utc};

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

#[derive(Debug, Serialize, ToSchema)]
pub struct GenerateRequest {
    pub kc_id: Uuid,
    pub difficulty: i32,
    pub count: i32,
    #[serde(default)]
    pub use_llm_wrap: bool,
    pub domain: Option<String>,
}
```

### 12.2 `src/handlers.rs`

```rust
use axum::{
    extract::{Path, State, Json},
    http::StatusCode,
};
use serde::Serialize;
use std::sync::Arc;
use uuid::Uuid;

use crate::models::*;
use crate::db::Db;
use shared::ApiResponse;

#[derive(Clone)]
pub struct AppState {
    pub db: Db,
}

pub async fn health() -> ApiResponse<shared::HealthResponse> {
    ApiResponse::ok(shared::health("question_bank"))
}

pub async fn curriculum(
    State(state): State<Arc<AppState>>,
) -> ApiResponse<Vec<CurriculumSubject>> {
    // Lấy curriculum từ content service hoặc local DB
    // Để đơn giản: trả về static hoặc gọi content service
    ApiResponse::ok(vec![])
}

pub async fn next_question(
    Path(student_id): Path<Uuid>,
    State(state): State<Arc<AppState>>,
) -> ApiResponse<Question> {
    // 1. Lấy KC hiện tại của student
    // 2. Lấy BKT state
    // 3. Dùng AdaptiveSelector để chọn câu
    // ...
    ApiResponse::err("Not yet implemented")
}

pub async fn submit_answer(
    Path(student_id): Path<Uuid>,
    State(state): State<Arc<AppState>>,
    Json(payload): Json<AnswerPayload>,
) -> ApiResponse<AnswerResult> {
    // 1. Lấy question để biết đáp án đúng
    // 2. So sánh answer_given với correct answer
    // 3. Lấy BKT state hiện tại từ DB
    // 4. Update BKT
    // 5. Lưu response log
    // 6. Trả về kết quả
    ApiResponse::ok(AnswerResult {
        is_correct: true,
        correct_answer: 3.0,
        p_mastery_new: 0.65,
        is_mastered: false,
        feedback: "Chính xác! Tiếp tục phát huy.".into(),
    })
}

pub async fn generate_questions(
    State(state): State<Arc<AppState>>,
    Json(req): Json<GenerateRequest>,
) -> ApiResponse<Vec<Question>> {
    // Chạy pipeline: template → sampler → generator → distractor
    // Lưu vào DB
    // Trả về danh sách question
    ApiResponse::ok(vec![])
}

pub async fn get_mastery(
    Path((student_id, kc_id)): Path<(Uuid, Uuid)>,
    State(state): State<Arc<AppState>>,
) -> ApiResponse<BktState> {
    let mastery = sqlx::query_as::<_, BktState>(
        "SELECT * FROM mastery WHERE student_id = $1 AND kc_id = $2"
    )
    .bind(student_id)
    .bind(kc_id)
    .fetch_optional(state.db.pool())
    .await;

    match mastery {
        Ok(Some(m)) => ApiResponse::ok(m),
        Ok(None) => ApiResponse::err("Mastery not found"),
        Err(e) => ApiResponse::err(&e.to_string()),
    }
}
```

### 12.3 `src/main.rs`

```rust
mod handlers;
mod models;
mod db;
mod engine;
mod llm;

use axum::{routing::get, Router};
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use handlers::AppState;
use models::{AnswerPayload, AnswerResult, BktState, GenerateRequest, Kc, Question, QuestionTemplate};

#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::health,
        handlers::next_question,
        handlers::submit_answer,
        handlers::generate_questions,
        handlers::get_mastery,
    ),
    components(schemas(
        Kc, QuestionTemplate, Question, BktState,
        GenerateRequest, AnswerPayload, AnswerResult,
    ))
)]
pub struct ApiDoc;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://qb_user:qb_pass@localhost:5432/qb_db".into());

    let db = match db::Db::connect(&db_url).await {
        Ok(d) => {
            tracing::info!("Connected to question bank database");
            if let Err(e) = d.run_migrations().await {
                tracing::warn!("Migration failed ({}), continuing", e);
            }
            d
        }
        Err(e) => {
            tracing::error!("Database connection failed: {}", e);
            panic!("Question bank service requires database");
        }
    };

    let state = Arc::new(AppState { db });

    let app = Router::new()
        .route("/api/questions/health", get(handlers::health))
        .route("/api/questions/next/:student_id", get(handlers::next_question))
        .route("/api/questions/answer/:student_id", axum::routing::post(handlers::submit_answer))
        .route("/api/questions/generate", axum::routing::post(handlers::generate_questions))
        .route("/api/questions/mastery/:student_id/:kc_id", get(handlers::get_mastery))
        .merge(
            SwaggerUi::new("/api/questions/swagger-ui")
                .url("/api/questions/openapi.json", ApiDoc::openapi()),
        )
        .layer(CorsLayer::permissive())
        .with_state(state);

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".into())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    
    tracing::info!("🚀 Question Bank service listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}
```

---

## 13. Tích hợp với Content Service

### 13.1 Gọi Content Service từ Question Bank

```rust
// src/llm/content_client.rs (bổ sung)
use reqwest::Client;
use serde::Deserialize;
use anyhow::Result;

#[derive(Debug, Deserialize)]
pub struct CurriculumSubject {
    pub subject_id: String,
    pub subject_vi: String,
    pub subject_en: String,
}

pub struct ContentClient {
    http: Client,
    base_url: String,
}

impl ContentClient {
    pub fn new(base_url: String) -> Self {
        Self { http: Client::new(), base_url }
    }

    pub async fn get_subjects(&self) -> Result<Vec<CurriculumSubject>> {
        let resp = self.http
            .get(format!("{}/api/content/subjects", self.base_url))
            .send().await?
            .json::<shared::ApiResponse<Vec<CurriculumSubject>>>().await?;
        
        Ok(resp.data.unwrap_or_default())
    }
}
```

### 13.2 Gọi Question Bank từ Frontend

```dart
// frontend/lib/services/question_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class QuestionApi {
  static const String baseUrl = 'http://localhost:8082/api/questions';

  static Future<Map<String, dynamic>> getNextQuestion(String studentId) async {
    final resp = await http.get(Uri.parse('$baseUrl/next/$studentId'));
    return jsonDecode(resp.body);
  }

  static Future<Map<String, dynamic>> submitAnswer(
    String studentId,
    String questionId,
    double answerGiven,
  ) async {
    final resp = await http.post(
      Uri.parse('$baseUrl/answer/$studentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': questionId,
        'answer_given': answerGiven,
        'time_taken_ms': 0,
      }),
    );
    return jsonDecode(resp.body);
  }
}
```

---

## 14. Chạy toàn bộ pipeline

### 14.1 Development

```bash
# Terminal 1: PostgreSQL (nếu chạy local)
docker run -d --name qb-postgres \
  -e POSTGRES_DB=qb_db \
  -e POSTGRES_USER=qb_user \
  -e POSTGRES_PASSWORD=qb_pass \
  -p 5432:5432 postgres:15-alpine

# Terminal 2: Question Bank service
cd math-app/backend
export DATABASE_URL=postgres://qb_user:qb_pass@localhost:5432/qb_db
cargo run -p question_bank

# Test health
curl http://localhost:3000/api/questions/health
# → {"success":true,"data":{"status":"ok","service":"question_bank","timestamp":"..."}}
```

### 14.2 Docker Compose (full stack)

```bash
cd math-app
docker compose up --build -d

# Test qua Traefik (port 8082)
curl http://localhost:8082/api/questions/health
```

### 14.3 Chạy generation pipeline

```bash
curl -X POST http://localhost:8082/api/questions/generate \
  -H "Content-Type: application/json" \
  -d '{
    "kc_id": "550e8400-e29b-41d4-a716-446655440000",
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
cd math-app/backend
cargo test -p question_bank bkt
```

### 15.2 Integration test với PostgreSQL

```rust
// src/main.rs (trong #[cfg(test)])
#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::PgPool;

    async fn setup_test_db() -> PgPool {
        let pool = PgPool::connect(
            "postgres://qb_user:qb_pass@localhost:5432/qb_db"
        ).await.unwrap();
        // Chạy migration
        let migrator = sqlx::migrate::Migrator::new(
            std::path::PathBuf::from("migrations")
        ).await.unwrap();
        migrator.run(&pool).await.unwrap();
        pool
    }

    #[tokio::test]
    async fn test_full_generation_pipeline() {
        let pool = setup_test_db().await;
        
        // Tạo KC
        // Tạo Template
        // Chạy sampler + generator + distractor
        // Kiểm tra output hợp lệ
        assert!(true); // placeholder
    }
}
```

### 15.3 Load test

```bash
# Cài hey
cargo install hey

# 100 concurrent requests
hey -n 1000 -c 100 http://localhost:8082/api/questions/health
```

---

## Checklist tích hợp

- [ ] Crate `question_bank` được thêm vào workspace
- [ ] `minijinja`, `meval`, `statrs` thêm vào workspace dependencies
- [ ] PostgreSQL schema migration chạy thành công
- [ ] KC seeded với quan hệ prerequisite
- [ ] Ít nhất 2 template per KC
- [ ] Sampler sinh được params hợp lệ
- [ ] Distractor generator sinh 3 sai đáp án per câu
- [ ] BKT update đúng chiều (correct → tăng, wrong → giảm)
- [ ] Adaptive selector chọn đúng difficulty dựa trên mastery
- [ ] API `/questions/next/:student_id` và `/answer/:student_id` hoạt động end-to-end
- [ ] LLM wrap hoạt động (có ANTHROPIC_API_KEY)
- [ ] Unit tests pass
- [ ] Docker compose chạy full stack không lỗi
- [ ] Frontend có thể gọi API question bank

---

## Tài liệu tham khảo

- [sqlx documentation](https://docs.rs/sqlx)
- [Axum Documentation](https://docs.rs/axum)
- [utoipa – OpenAPI for Axum](https://docs.rs/utoipa)
- [Corbett, Anderson (1994) — Knowledge Tracing](https://dl.acm.org/doi/10.1007/BF01099821)
- [pyBKT — reference implementation](https://github.com/CAHLR/pyBKT)
- [Minijinja templating](https://docs.rs/minijinja)
- [meval – math expression evaluator](https://docs.rs/meval)
- [math-app backend README](backend/README.md)
