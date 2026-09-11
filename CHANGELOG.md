# Changelog

All notable changes to HocVui are documented here. The canonical full changelog lives at [docs/math-app/CHANGELOG.md](docs/math-app/CHANGELOG.md).

## [Unreleased]

### Added — Test Coverage (124 new tests)
- **auth:** 5 inline tests for `refresh_token` edge cases (valid, missing, invalid, expired-within-grace, expired-beyond-grace)
- **question_bank:** 14 integration tests covering all 9 routes (health, mastery, review, generate, answer, hint)
- **progress:** 15 integration tests covering all 12 routes (progress, streak, daily-limit, batch, achievements, exercise-stat, review-session, score)
- **notification:** 15 integration tests (replaced 11 stale tests, added 6 new handler tests: send-test, subscribe, unsubscribe, status, preferences, send-report)
- **language (Python):** 47 tests — `test_text_check.py` (41 tests: remove_vietnamese_tones, levenshtein_distance, validate_text) + `test_audio_storage.py` (6 tests: ensure_bucket, upload_audio, get_audio_stream)
- **frontend (Flutter):** 33 tests — `app_providers_test.dart` (17), `app_router_test.dart` (5), `home_screen_test.dart` (4), `exercise_widgets_test.dart` (7)
- **e2e:** Fixed missing `recordRequests` export in `e2e/utils/auth.ts`

### Added — SEO Fixes (11 code-level issues fixed)
- Removed `/brand/` route from flutter-web Traefik router — was intercepting marketing-site brand assets (404)
- Fixed `/sitemap.xml` — was 301 redirect, now serves content directly (200)
- Stripped CSP/security headers from sitemap XML responses — Google Search Console couldn't fetch sitemap ("Không thể tìm nạp"). Added separate Traefik router for sitemap/robots paths with no CSP middleware
- Removed stale `plausible.io` from CSP — site uses self-hosted Umami
- Fixed hreflang: `vi`→`vi-VN`, `en`→`en-US` to match JSON-LD
- Removed fake `aggregateRating` (4.8/1280) from JSON-LD — Google penalty risk
- Fixed broken `noindex` on `/404`, `/privacy`, `/terms` — prop was passed at wrong level, Google was indexing these
- Added `twitter:site` and `twitter:creator` meta tags (`@hocvui`)
- Added `<lastmod>` to sitemap entries via astro `serialize()` callback
- Replaced invalid `Article` JSON-LD on `/personas` with `ItemList`
- Added `PUBLIC_GSC_VERIFICATION` env support in BaseLayout

### Changed — Pricing Overhaul
- **Monthly:** 199,000 đ → **39,000 đ** (~$1.59/mo)
- **Yearly:** 1,990,000 đ → **390,000 đ** (~$15.90/yr)
- **Free tier:** 50 lessons/day → **unlimited lessons** (no daily cap)
- Premium is now features-only upsell: email reports, multi-child, CSV export, priority support, early access, no ads
- Backend `progress/handlers.rs`: `has_reached_limit: false`, `limit: 0`
- Frontend `daily_limit.dart`: `freeTierDailyLimit = 0`, `shouldShowPaywall()` always returns false
- Paywall modal messaging changed from daily limit to premium features
- Pricing banner: removed daily limit check, soft upsell only
- Marketing site pricing pages + JSON-LD updated with new prices
- `pricing.json` version bumped to 2; validator updated

### Changed — Security Fixes (12 issues from PROJECT_ISSUES_AUDIT.md)
- `user/handlers.rs`: `update_grade` now scoped `WHERE id = $2` with auth claims
- `auth/`: Removed broken `register` endpoint
- `payment/`: Added Stripe-Signature HMAC-SHA256 verification
- Deleted root `google-services.json`, added to `.gitignore`
- `shared/lib.rs`: Added `cors_layer()` helper; replaced `CorsLayer::permissive()` across 7 services + Python
- `auth/handlers.rs`: JWT refresh grace 30d→7d
- `auth/main.rs`: Added `RateLimiter` (10/min) on login endpoints
- `language/audio_storage.py`: Fail-fast on missing MinIO creds
- All 7 service main.rs: `.unwrap()`→`.expect()` on TCP bind + server start
- Created `.dockerignore` files
- `language/main.py`: Added structured logging
- `frontend`: Created `app_constants.dart` for contact URL

### Changed — Docs Reorganization
- Moved `PROJECT_ISSUES_AUDIT.md` → `docs/`
- Moved `FEATURE_IDEAS.md` → `docs/`
- Moved `DOTA.md` → `docs/`
- Root `README.md` rewritten — clean overview, points to `docs/` for details
- Root `CHANGELOG.md` — recent changes summary (canonical at `docs/math-app/CHANGELOG.md`)

### Deployed
- All security fixes deployed to VPS (commit `e58fce9`)
- 50 fake Vietnamese leaderboard users added to production `user_scores` table
- SEO fixes deployed to VPS marketing site
- Pricing changes deployed to VPS marketing site

### Test Results
| Suite | Passed | Failed | Ignored | New Tests |
|-------|--------|--------|---------|-----------|
| Rust backend | 173 | 0 | 94 | +44 integration |
| Python | 95 | 0 | 0 | +47 unit |
| Flutter | 33 | 0 | 0 | +33 widget/unit |
| **Total** | **301** | **0** | **94** | **+124 new** |

---

For earlier changes, see [docs/math-app/CHANGELOG.md](docs/math-app/CHANGELOG.md).
  - **`/sitemap.xml` returned HTML instead of XML** — nginx had an exact-match `location = /sitemap-index.xml` but no rule for `/sitemap.xml`; Astro sitemap generates only `sitemap-index.xml` + `sitemap-0.xml`, so `/sitemap.xml` fell through to `try_files ... /index.html` and served the homepage (HTTP 200, 22KB HTML). Google Search Console sitemap submission failed silently. Fix: added `location = /sitemap.xml { return 301 /sitemap-index.xml; }` so the conventional sitemap URL redirects to the real index.
  - **Soft 404 — `/nonexistent` returned HTTP 200 with homepage content** — nginx `try_files $uri $uri/ $uri.html /index.html` fell back to `/index.html` for any non-existent path, producing a soft 404 (duplicate-content SEO penalty). Astro generates `dist/404.html`. Fix: changed fallback to `/404.html` and added `location = /404.html { internal; return 404; }` so missing paths return a real 404 status.
  - **`/en` + all directory redirects downgraded scheme to `http://`** — nginx emitted `Location: http://sekklings.com/en/` (absolute, http) because Traefik terminates TLS and nginx saw the request as http. This created a wasteful 301→http→301→https redirect chain for `/en`, `/pricing`, `/parents`, `/about`, `/blog`, `/personas`, `/lessons`, `/newsletter`, `/privacy`, `/terms`. Fix: added `absolute_redirect off; port_in_redirect off;` to the nginx `server` block so nginx emits relative redirects (`/en/`) and the scheme is preserved by the TLS-terminating proxy.
  - **`/app/` (Flutter web) missing security headers** — the `flutter-web`, `flutter-canvas`, and `flutter-assets` Traefik routers only applied a `flutter-coop` middleware (COOP header). HSTS, X-Frame-Options, X-Content-Type-Options, Permissions-Policy, and Referrer-Policy were missing (present on the marketing site via `marketing-csp` middleware but not on Flutter routes). Fix: added a `flutter-headers` Traefik middleware with `stsSeconds=31536000`, `stsIncludeSubdomains=true`, `customFrameOptionsValue=SAMEORIGIN`, `contentTypeNosniff=true`, `permissionsPolicy=geolocation=(), microphone=(), camera()`, `referrerPolicy=strict-origin-when-cross-origin`, and appended it to all three Flutter routers. CSP is intentionally omitted for Flutter web (wasm + eval requires a permissive policy — tracked as a separate task).

- **Test suite — pre-existing failures from prior refactors** (4 stale test files)
  - **`flutter test` — `intl` version pin conflict** (`frontend/pubspec.yaml`): `intl ^0.19.0` was incompatible with `flutter_localizations` which requires `intl 0.20.2`. Fix: bumped to `^0.20.2`.
  - **`flutter test` — `google_fonts 6.3.0` const-eval bug on Flutter 3.44** (`frontend/pubspec.yaml`): `google_fonts_variant.dart:152` failed `const` evaluation of `FontWeight` keys on the local Flutter SDK. Fix: bumped `google_fonts ^6.2.1` → `^6.3.3` (patch fix, no breaking API changes).
  - **`test/widget_test.dart` — stale `MathApp(autoSignedIn:)` param**: the `autoSignedIn` parameter was removed from `MathApp` in a prior refactor. Fix: `const MathApp(autoSignedIn: false)` → `const MathApp()`.
  - **`test/services/lesson_unlock_test.dart` — stale `lessons:` argument**: `nextUnlockedLesson` signature changed from `lessons: List<ApiLesson>` to `bySubject: Map<String, List<ApiLesson>>` (perf refactor commit `ce20879`). Fix: added `_bySubject()` helper and converted all 10 call sites.
  - **`test/screens/profile_screen_test.dart` — stale `curriculumProvider`**: `curriculumProvider` was removed and replaced by `subjectsProvider`. Fix: replaced 2 references.
---

For earlier changes, see [docs/math-app/CHANGELOG.md](docs/math-app/CHANGELOG.md).
