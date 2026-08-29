# Project Issues Audit — HocVui Math App

**Date:** 2026-08-29
**Auditor:** Automated security + code quality scan
**Scope:** Full repo at `/home/s0lut1on/project/learning/math`

---

## Summary

| Severity | Count | Key Issues |
|----------|-------|------------|
| 🔴 Critical | 4 | Mass grade update, plaintext passwords, no Stripe webhook verification, Firebase key on disk |
| 🟠 High | 4 | Wildcard CORS, 30-day JWT refresh, no rate limiting, default MinIO creds |
| 🟡 Medium | 4 | unwrap() in prod, no .dockerignore, no Python logging, console.log |
| 🟢 Low | 3 | Manual SQL escaping, hardcoded URL, duplicate file |

---

## 🔴 CRITICAL (Fix immediately)

### 1. `update_grade` overwrites ALL users' grade

- **File:** `math-app/backend/user/src/handlers.rs:170`
- **Issue:** `UPDATE users SET grade = $1` — no `WHERE` clause, no user scoping. Auth middleware extracts `claims.sub` but handler never uses it. Any authenticated user calling `/api/users/grade` changes every user's grade in the database.
- **Fix:** Add `WHERE id = $2` bound to the authenticated user's UUID.

```rust
// CURRENT (broken):
let result = sqlx::query("UPDATE users SET grade = $1")
    .bind(body.grade)
    .execute(&state.db)
    .await;

// FIX:
let user_id = match uuid::Uuid::try_parse(&claims.sub) {
    Ok(u) => u,
    Err(_) => return shared::ApiResponse::err("Invalid user_id"),
};
let result = sqlx::query("UPDATE users SET grade = $1 WHERE id = $2")
    .bind(body.grade)
    .bind(user_id)
    .execute(&state.db)
    .await;
```

### 2. Passwords stored in plaintext / auth flow broken

- **File:** `math-app/backend/auth/src/handlers.rs:133-167` (register endpoint)
- **Issue:** `RegisterRequest` accepts `password`, validates length ≥6, but never hashes it. Password is never stored anywhere (no INSERT into users table), but also never verified on login. The entire email/password auth flow is broken — registration issues a JWT without persisting credentials, and there's no login endpoint for email/password.
- **Fix:** Either remove password-based auth entirely (Google OAuth + guest login work), or implement proper bcrypt hashing + storage + verification.

### 3. Stripe webhook has no signature verification

- **File:** `math-app/backend/payment/src/handlers.rs:71-107`
- **Issue:** `stripe_webhook` parses raw JSON body and trusts it. `STRIPE_WEBHOOK_SECRET` is passed to the container (docker-compose.yml:177) but never read. Anyone can POST a fake `checkout.session.completed` event and get premium tier for free.
- **Fix:** Verify `Stripe-Signature` header using `STRIPE_WEBHOOK_SECRET` with HMAC-SHA256 before processing the event.

### 4. Firebase API key committed to git

- **Files:** `google-services.json:31`, `math-app/frontend/android/app/google-services.json:31`
- **Issue:** Both files contain `AIzaSyAZb5G9uSmA7bo43Lk1CJt9RL3S06SaXPM` and are NOT in `.gitignore`. The root `google-services.json` is untracked but present on disk.
- **Note:** Firebase Android API keys are technically public (embedded in the app), but the root-level copy shouldn't exist. The `android/app/` copy is required for the build.
- **Fix:** Delete root `google-services.json`. Add `google-services.json` to root `.gitignore` but keep `math-app/frontend/android/app/google-services.json` (required for Gradle, already not tracked by git).

---

## 🟠 HIGH

### 5. CORS wildcard on 7 of 9 services

- **Files:** `user`, `media`, `question_bank`, `progress`, `content`, `payment`, `notification` use `CorsLayer::permissive()` (allows all origins). Python `language` service uses `allow_origins=["*"]`.
- **Issue:** Only `auth` service properly restricts origins to `sekklings.com` + `www.sekklings.com`. All other services accept requests from any origin.
- **Fix:** Apply the same restricted CORS policy to all services.

### 6. JWT refresh accepts expired tokens for 30 days

- **File:** `math-app/backend/auth/src/handlers.rs:226`
- **Issue:** `validation.validate_exp = false` in `refresh_token`. A token expired 30 days ago can be refreshed. If a token is stolen, the attacker has a 30-day window even after expiry.
- **Fix:** Shorten grace period to 1-7 days, or use a separate refresh token with rotation.

### 7. No rate limiting on auth endpoints

- **Issue:** `login_with_google`, `register`, `guest_login`, `refresh_token` have no rate limiting. Only the AI hint endpoint has a rate limiter (`hint_cache.rs`).
- **Fix:** Add per-IP rate limiting to auth endpoints (e.g., 10 login attempts/minute).

### 8. MinIO credentials default to `minioadmin/minioadmin`

- **Files:** `math-app/backend/media/src/handlers.rs` (via env), `math-app/backend/language/src/services/audio_storage.py:7-8`
- **Issue:** Both services default to `minioadmin/minioadmin` if env vars are missing. In dev this is fine; in prod, a misconfigured deploy exposes all uploaded media.
- **Fix:** Fail fast if `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY` are not set in production.

---

## 🟡 MEDIUM

### 9. `unwrap()` in production code paths

- **Files:** Multiple `main.rs` files use `.unwrap()` for TCP listener bind and server start. `auth/src/handlers.rs:136` uses `Regex::new(...).unwrap()` in a `OnceLock`.
- **Risk:** These are startup-time panics (acceptable for fail-fast), but the regex unwrap could panic at first request if the pattern is invalid.
- **Fix:** Use `expect()` with descriptive messages for startup unwraps. The regex is static and safe, but `expect()` is better practice.

### 10. No `.dockerignore`

- **Issue:** No `.dockerignore` files found. Docker builds copy everything, including `.git`, `node_modules`, `target/`, `.dart_tool/`, test artifacts, and `.env.deploy` (which contains VPS IP and Google Client ID).
- **Fix:** Add `.dockerignore` excluding `.git`, `node_modules`, `target`, `.dart_tool`, `build`, `.env*`, `test-results`, `.playwright-mcp`.

### 11. Python service has no logging

- **File:** `math-app/backend/language/src/main.py`
- **Issue:** No `logging` configuration. Errors go to stdout via FastAPI defaults but aren't structured. Rust services properly use `tracing`.
- **Fix:** Add `logging.basicConfig()` or use `structlog`/`loguru` for structured logging.

### 12. `console.log` in production scripts

- **Files:** `math-app/e2e/shoot_flutter.js`, `shoot-design.js`, `screenshot_time_lesson.js`
- **Issue:** These are e2e utility scripts, not production code. Low risk but should use proper logging if run in CI.
- **Fix:** Acceptable as-is for e2e scripts.

---

## 🟢 LOW

### 13. SQL generation scripts use manual escaping

- **Files:** `math-app/scripts/generate_curriculum.py:30`, `generate_grade2_curriculum.py:23`
- **Issue:** `escape_sql()` is a hand-rolled SQL string escaper. The generated INSERT statements use string interpolation. This is for seed data generation, not runtime, so risk is low.
- **Fix:** Acceptable for offline scripts. If ever made interactive, switch to parameterized queries.

### 14. Hardcoded Facebook URL in app

- **File:** `math-app/frontend/lib/widgets/kid_nav_bar.dart:64`
- **Issue:** Facebook page URL is hardcoded. Not a security issue, but a maintainability one.
- **Fix:** Move to config or l10n.

### 15. `google-services.json` duplicated at repo root

- **Issue:** The file exists at both `./google-services.json` and `./math-app/frontend/android/app/google-services.json`. The root copy is unnecessary.
- **Fix:** Delete root copy.

---

## Top 3 to Fix Now

1. **`update_grade` missing WHERE clause** — data corruption risk, any user can change all users' grades
2. **Stripe webhook no signature verification** — payment bypass, anyone can forge premium access
3. **CORS permissive on all services except auth** — credential theft via CSRF from any origin