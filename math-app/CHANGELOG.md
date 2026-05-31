# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed
- **Parent access button hidden from login screen** — `_buildParentLink()` removed from `_buildMobile()` and `_buildDesktop()` in `frontend/lib/screens/login_screen.dart`
- **GitHub Actions workflow moved to repo root** — `.github/workflows/*.yml` moved from `math-app/.github/workflows/` to `.github/workflows/` so GitHub can detect and run them
- **CI/CD `IMAGE_TAG` bug fixed** — `docker compose pull` now passes `IMAGE_TAG` to pull the correct SHA-tagged images instead of stale `:latest`
- **Invalid `script_stop` input removed** from `appleboy/ssh-action` step to eliminate workflow warnings
- **E2E workflow paths fixed** — `cd e2e` → `cd math-app/e2e`, `make docker-dev` → `cd math-app && make docker-dev`, artifact path `e2e/playwright-report/` → `math-app/e2e/playwright-report/` to match repo structure after moving workflows to root
- **CI workflow paths fixed** — `./frontend` → `./math-app/frontend`, `backend/Dockerfile` → `math-app/backend/Dockerfile` in `ci.yml`
- **Login screen mobile layout fixed** — title, Google button, divider, and guest button were missing from `_buildMobile()`; added them so the login screen is usable on phones
- **Flutter SDK version fixed** — downgraded `intl` constraint from `^0.20.2` to `^0.19.0` to match `flutter_localizations` SDK pin; regenerated `pubspec.lock`
- **Makefile `DART_CMD` fixed** — changed fallback from system `dart` to `$(dirname $(which flutter))/dart` so `make format` works when local Flutter SDK is absent but system `flutter` is in `PATH`

### Security
- **JWT `aud` (audience) claim added** — prevents token replay across services. `aud: "math-app"` included in all tokens. `auth_middleware` in `shared/src/lib.rs` validates `aud` via `HashSet`
- **Guest token expiry reduced** — from 365 days to 30 days in `login_as_guest`
- **Email validation added** — `register` endpoint validates email format via `Regex` and password length ≥ 6; `regex` crate added to workspace dependencies
- **Rate limiting added** — `tower-http` limit feature enabled on auth endpoints; `tower` added to `auth/Cargo.toml`
- **Production Docker Compose config** — `docker-compose.prod.yml` created with Traefik HTTPS on 443, HTTP→HTTPS redirect, Let's Encrypt TLS auto-certs
- **DB credentials moved to `.env`** — all 7 services' `DATABASE_URL` hardcoded values removed from `docker-compose.yml`
- **MinIO console secured** — removed port `9003` mapping from `docker-compose.yml`; console only via `docker exec`
- **`.gitignore` created** — protects `.env`, secrets, build artifacts, credentials
- **JWT secret hardcoded vulnerability fixed** — removed hardcoded `"secret"` from `login_with_google`, `register`, and `login_as_guest` in `backend/auth/src/handlers.rs`; all JWT signing now requires `JWT_SECRET` environment variable via `std::env::var("JWT_SECRET").expect(...)`
- **Token expiration validation enabled** — changed `validation.validate_exp = false` to `true` in `backend/auth/src/handlers.rs` (line ~163); expired tokens are now rejected
- **JWT_SECRET added to `.env`** — `JWT_SECRET=change-this-to-a-random-256-bit-key-in-production` with generation instructions (`openssl rand -base64 32`)
- **Error message leakage fixed across all services** — replaced `ApiResponse::err(&format!("Failed: {}", e))` and `ApiResponse::err(&e.to_string())` with generic `"Internal server error"` responses + `tracing::error!()` logging in:
  - `backend/progress/src/handlers.rs` (4 endpoints)
  - `backend/user/src/handlers.rs` (`get_user`, `create_user`)
  - `backend/content/src/handlers.rs` (`get_lesson`)
  - `backend/media/src/handlers.rs` (`list_media`)
  - `backend/notification/src/handlers.rs` (`list_notifications`)
  - `backend/question_bank/src/handlers.rs` (`submit_answer`, `generate_questions`, `get_mastery`)
- **Auth middleware** — TODO: protect progress, user, content, media, notification, question_bank endpoints

### Fixed
- **Language switch no longer logs user out** — `MathApp` converted from `ConsumerWidget` to `ConsumerStatefulWidget`; `AppRouter` is now instantiated once in `initState()` instead of on every `build()`. Changing `localeProvider` caused a full `MaterialApp` rebuild, which recreated `GoRouter` with stale `initialSignedIn` and reset the route to `/login`. Now the router instance is cached and survives locale changes. Nginx cache control added for SPA entry files to prevent browsers from serving stale JS after rebuilds.
- **Redis hostname typo fixed** in `docker-compose.prod.existing-proxy.yml` — `content-service` had `REDIS_URL=redis://nginx:6379` instead of `redis://redis:6379`; this would have caused the content service to fail startup when deploying via Option A
- **Traefik router rules fixed** in `docker-compose.prod.yml` — all 7 API service rules used single `&` (bitwise AND) instead of `&&` (logical AND). Traefik requires `&&` for compound Host+PathPrefix matching; without this fix, all API routes return 404 on a fresh dedicated VPS deployment

### Changed
- **`VPS_DEPLOY.md` dedicated VPS path streamlined** — Step 3.2 now instructs users to use the existing `docker-compose.prod.yml` directly (with `DOMAIN` and `LETSENCRYPT_EMAIL` in `.env`) instead of manually replacing inline YAML inside `docker-compose.yml`. Eliminates copy-paste errors and keeps the dedicated VPS compose file under version control
- **`VPS_DEPLOY.md` deploy command corrected** — Step 4.3 now uses `docker compose -f docker-compose.prod.yml up --build -d` instead of `docker-compose.yml`, matching the actual file name in the repo

### Added
- **CI/CD pipeline via GitHub Actions** (`.github/workflows/deploy.yml`) — on every push to `main`, GitHub Actions builds all 8 Docker images (`flutter-web` + 7 backend services) for `linux/amd64`, pushes them to GitHub Container Registry (`ghcr.io`) with tags `:latest` and `:<sha>`, then SSHs to the VPS, logs into GHCR, pulls new images, and restarts services. Includes post-deploy `./scripts/health-check.sh` verification of all 8 service endpoints
- **`docker-compose.ghcr.yml`** — production compose file that pulls pre-built GHCR images instead of building on the VPS, cutting cold-start deploy time from 5–10 min to under 2 min. Uses `OWNER_REPO` and `IMAGE_TAG` env vars so the same file works across forks and image versions
- **`scripts/health-check.sh`** — standalone VPS health checker that curls every `/health` endpoint (`auth`, `user`, `content`, `progress`, `notification`, `media`, `question-bank`) plus Traefik root, curriculum API, and auth behavior (401 without token, 405 on POST-only). Returns exit code 0 only if all pass
- **`OWNER_REPO` added to `.env.example`** — used by `docker-compose.ghcr.yml` to construct the full GHCR image path (defaults to `your-username/math-app` for one-time setup)
- **`LETSENCRYPT_EMAIL` added to `.env.example`** — required by Traefik for Let's Encrypt certificate notifications in dedicated VPS mode. Documented as optional (only needed for `docker-compose.prod.yml`)
- **VPS_DEPLOY.md Option A overhaul** — added Step A2 (create `.env`), Step A3 (pre-deploy disk/cache checks), Step A4 (build with verification), Step A5 (nginx config safety with `nginx -t` before reload), Step A6 (health verification), Step A7 (redeploy script). Documents zero-downtime reload pattern and warns about testing nginx config before enabling

### Added
- **Production deployment for existing reverse proxy** — `docker-compose.prod.existing-proxy.yml` created for deployments where Nginx/Apache/Caddy/Traefik already occupies port 80/443. All services bind to `127.0.0.1:PORT` only (no public exposure). `nginx-sample-existing-proxy.conf` provides a ready-to-use Nginx upstream config for all 8 services
- **Documentation updated** — `README.md` (root + `math-app/`) now documents all new features: auth/profile, free/premium tiers, `ClockFace` widget, `ProfileScreen`/`SettingsScreen` routes, route guards, token validation, subscription tier management section with DB commands
- **Subscription tier management docs** — added section in `math-app/README.md` explaining flag-based free/premium model, DB command to flip `subscription_tier`, and planned parent-dashboard UI path

### Added
- **Comprehensive test coverage expansion** across all layers (Rust, Flutter, E2E)
  - Rust backend: auth serde roundtrip tests (7), progress serde tests (5), shared tests (8), auth handler tests (5 including register/health/me/JWT), progress UUID parser tests (3), streak calculation tests (4). Refactored `parse_uuid` helper extracted in progress handlers; reused in streak update.
  - Flutter frontend: `clock_face_test.dart` widget tests (8), `paywall_modal_test.dart` dialog tests (4), `user_model_test.dart` tier/premium tests (7), `progress_api_test.dart` API mocking tests (9)
  - E2E Playwright: `progress.spec.ts` (5 tests for daily-limit/progress/streak), `lesson_flow.spec.ts` (3 API tests), extended `auth.spec.ts` with tier and unauthorized tests (2), extended `smoke.spec.ts` with individual health checks (2)
  - E2E total: 44 tests (was 32)
  - Backend: extracted `compute_new_streak` pure function from `update_streak` for testability

### Added
- **Free/Premium subscription tier** — minimal flag-based implementation without payment gateway
  - Backend DB migrations: `backend/user/migrations/003_subscription_tier.sql`, `backend/auth/migrations/002_subscription_tier.sql`, `backend/progress/migrations/002_daily_lessons.sql`
  - Backend auth models: `AuthUser.subscription_tier`, `Claims.tier`, `MeResponse.tier` fields added
  - Backend auth handlers: all login methods include `tier: "free"` in JWT; `/auth/me` returns `tier`
  - Backend progress: `DailyLessonCount`, `DailyLimitStatus` models; `GET /api/progress/daily-limit/:user_id` endpoint; `update_progress` increments daily count
  - Frontend User model: `tier` field, `isPremium` getter, `copyWith` updated
  - Frontend providers: `currentUserTierProvider` exposes tier
  - Frontend ProgressApi: `getDailyLimit()` method
  - Frontend LessonScreen: checks daily limit on init; `_finishLesson` blocks completion after 50 lessons/day with `PaywallModal`
  - Frontend widget: `PaywallModal` shows "50 lessons/day reached" and upgrade prompt

### Added
- **Root README.md** — project overview, quick start, layout, features, tech stack
- **Profile Widget replaces desktop nav Start button**
  - Backend: `GET /api/auth/me` endpoint with JWT decoding; `MeResponse` model added to `backend/auth/src/models.rs`
  - Frontend: `AuthService` — `getCurrentUser()` with `authStateChanges` broadcast stream; emits on sign-in/out
  - Frontend: `ProfileWidget` (avatar + name + dropdown: Profile/Settings/Logout) in `widgets/profile_widget.dart`; null-safe `AppLocalizations` access for tests
  - Frontend: `ProfileScreen` full profile page at `/profile` with stats, avatar, logout
  - Frontend: Replaced desktop nav "Bắt đầu" button with `ProfileWidget` in `WelcomeScreen._buildDesktopNav()`
  - Frontend: Added `/profile` route in `app_router.dart`
  - Frontend: i18n strings added (`profile`, `settings`, `logout`, `guestUser`, `comingSoon`, `profileTitle`) to `app_en.arb` + `app_vi.arb`; regenerated via `flutter gen-l10n`
  - Frontend: `app_providers.dart` — added `authUserProvider` (StreamProvider), `currentUserProvider` (FutureProvider)
  - Tests: `auth_service_test.dart` — `getCurrentUser` success/failure tests; `profile_widget_test.dart` — 3 widget tests
- **Login Screen as Initial Route**
  - `frontend/lib/screens/login_screen.dart` — new dedicated login page with Google Sign-In + "Tiếp tục không đăng nhập" + "Dành cho phụ huynh"
  - `frontend/lib/core/app_router.dart` — new `/login` route; `initialLocation` changed from `/` to `/login`; `WelcomeScreen` now at `/welcome`
  - `frontend/lib/main.dart` — auto-sign-in now redirects to `/home` instead of `/`
  - Login success redirects to `/welcome` (persona selection) before entering app
  - E2E tests updated to use `/login` as entry point instead of `/`
- **Unit Tests for Login & Auth**
  - `frontend/test/screens/login_screen_test.dart` — 6 tests: renders mascot/title, Google button visible, guest button visible, parent link visible, divider visible, dialog interaction
  - `frontend/test/services/auth_service_test.dart` — 5 tests: guest login success/failure, sign-out clears token, silent sign-in with/without stored token
  - `frontend/test/helpers/mock_dio.dart` — added `/auth/guest` mock response
- **Google Sign-In Web Support**
  - `frontend/web/index.html` — removed `<meta>` COOP/COEP tags; added `<meta name="google-signin-client_id">` and `<meta name="google-signin-scope">` meta tags for `google_sign_in_web` plugin
  - `frontend/nginx.conf` — changed `Cross-Origin-Opener-Policy` to `unsafe-none`, added `Cross-Origin-Embedder-Policy: unsafe-none`
  - `docker-compose.yml` — Traefik middleware `flutter-coop` sends COOP `unsafe-none` header (GIS SDK requires no COOP to detect popup closure)
  - `frontend/lib/services/auth_service.dart` — `signInWithGoogle()` now falls back to `access_token` when `id_token` is null (Google Identity Services on web returns access_token instead of id_token)
  - `backend/auth/src/handlers.rs` — `login_with_google` now accepts both `id_token` (mobile/desktop) and `access_token` (web), verifies access_token via Google OAuth2 userinfo endpoint
  - `backend/auth/src/models.rs` — `GoogleLoginRequest` fields `id_token` and `access_token` are now both `Option<String>`
- **Subject Screen** (`frontend/lib/screens/subject_screen.dart`)
  - New `/subject/:subjectId` route in `app_router.dart`
  - Displays subject header with localized title, icon, and color
  - Lists all lessons for the subject with difficulty badges and premium stars
  - Tapping a lesson navigates to `/lesson/{subjectId}/{lessonId}`
- **E2E tests for Subject navigation** (`e2e/tests/navigation.spec.ts`)
  - Deep link to `/subject/numbers` works
  - Subject page renders lesson cards
  - Clicking lesson navigates to correct lesson URL
- **Dynamic Lesson Progression**
  - `ProgressApi.getUserProgress(userId)` + `getUserStreak(userId)` frontend client methods
  - `userProgressProvider` (Riverpod) loads completed lesson IDs from backend
  - `totalStarsProvider` computes aggregate stars across completed lessons
  - `nextLessonProvider` resolves the first unlocked-but-uncompleted lesson across subjects
  - `SubjectScreen` now shows lesson status: locked (gray, lock icon), unlocked (pink), completed (green checkmark + stars)
  - Unlock rule: first lesson of each subject always unlocked; lesson N requires lesson N-1 completed in same subject
  - `CelebrationScreen` "Next" button now navigates to next lesson in same subject instead of always returning home
  - `HomeScreen` "Continue learning" card now navigates to the real next unlocked lesson instead of hardcoded `lesson_n1`/`lesson_n2`
  - `HomeScreen` stats (desktop) now show actual completed lesson count and total stars instead of hardcoded `12` and `3 ⭐`
- **Backend Progress API improvements**
  - New `GET /api/progress/:user_id` — returns this user's completed lessons + stars
  - New `GET /api/progress/streak/:user_id` — returns streak data for a user
  - Streak update logic on lesson completion: increments `current_streak` if last activity was yesterday, resets to 1 if missed a day
  - Fixed `update_progress` to reject invalid UUIDs instead of silently creating random users
  - `changelog-check` target ensures [Unreleased] section exists
  - `deploy` sequence: format → lint → changelog-check → test-all → build-web → build-rust → docker-dev → e2e-test
  - Added `CONTRIBUTING.md` with required workflow rules
- **Question Bank microservice** (`backend/question_bank/`)
  - Parametric math question generation with MiniJinja templates + meval expressions
  - Bayesian Knowledge Tracing (BKT) for adaptive difficulty
  - Distractor generation based on error taxonomy
  - LLM word problem wrapping stub (Anthropic Claude)
  - PostgreSQL schema: KC graph, templates, questions, mastery states, responses
  - Axum handlers: `next_question`, `submit_answer`, `generate_questions`, `get_mastery`
  - Swagger UI at `/api/questions/swagger-ui`
  - Docker Compose service + database
- **Playwright E2E tests** (`e2e/`)
  - API health checks for all 7 microservices
  - Web smoke tests: welcome page loads, title check
  - Page load verification for home, lesson, celebration, parent-dashboard, pin-gate
  - Auto-starts Docker services if not running
  - GitHub Actions workflow (`.github/workflows/e2e.yml`)
- **Enhanced Language Switcher**
  - Replaced `CupertinoSlidingSegmentedControl` with a custom animated `ToggleButton` for cleaner visuals and consistent theming across light/dark modes.
  - Added localized hint text in `ToggleButton` to provide context for language selection.
  - Improved state management in `WelcomeScreen` to correctly synchronize language selection with `Riverpod`.

### Changed
- `backend/content/src/models.rs`: `get_curriculum()` now uses a single LEFT JOIN query instead of N+1 queries — critical for 1,700+ lessons
- `CelebrationScreen` route now accepts `subjectId` + `lessonId` via extra data for accurate next-lesson navigation
- `lesson_screen.dart`: `currentQuestion` is now mutable to support retry; lesson only completes after ALL exercises answered correctly

### Added
- **Route guards — protected routes require authentication**
  - `app_router.dart` — `GoRouter` now has `redirect` + `refreshListenable` via `ValueNotifier`
  - Public routes: `/login`, `/welcome`; all others redirect to `/login` when no token
  - Authenticated users on `/login` are redirected to `/welcome`
  - `main.dart` — restored token now also sets `AuthService().tokenNotifier.value`
  - E2E tests updated — page-load tests now verify redirect to `/login` for protected routes
- **E2E auth tests** (`e2e/tests/auth.spec.ts`) — 11 tests: guest login API, auth/me with/without token, route guards for all protected pages, public route accessibility

### Fixed
- **E2E route guard tests flaked on repeated runs** — browser context carried localStorage JWT across tests. Fixed by adding `storageState: { cookies: [], origins: [] }` to Playwright config so each test starts with a completely clean browser context. Also added `test.beforeEach` with `localStorage.clear()` + `sessionStorage.clear()` + `page.goto('/login')` in `auth.spec.ts` and `onboarding.spec.ts` for extra isolation. All 44 E2E tests now pass reliably. — JWT `sub` contained Google numeric `sub` (e.g., `117292929...`) instead of database UUID
  - `backend/auth/src/handlers.rs` — `login_with_google` now INSERT/SELECT to get the actual `users.id` UUID and stores that in JWT `sub`
  - `me()` endpoint now returns a valid UUID `id` compatible with `progress.user_id` (UUID type)
- **Guest lesson completions were silently lost** — root cause was `userIdProvider` never set for guest users
  - `main.dart` — added `ref.listen(currentUserProvider, ...)` that auto-extracts `id` from `/auth/me` response and sets `userIdProvider`
  - `ProfileWidget._handleLogout()` now clears `userIdProvider` and invalidates `userProgressProvider` to prevent stale data
  - Flow: guest login → JWT `sub` UUID set → `/auth/me` returns `id` → `userIdProvider` set → `ProgressApi.updateProgress()` called → database row created
  - `currentUserProvider` now watches `authUserProvider` stream to auto-refetch after sign-in
  - `ProfileScreen` made null-safe for `AppLocalizations` access
- **Google user avatar now loads correctly with error fallback**
  - Replaced `CircleAvatar` with `NetworkImage` (which silently fails) with `Image.network` + `errorBuilder` in both `ProfileWidget` and `ProfileScreen`
  - Avatar falls back to initial-letter avatar on image load error
  - Added debug logging (`debugPrint`) for avatar URL and load errors in debug mode
- Answer box text overflow: `_buildOptions` in `lesson_screen.dart` changed from fixed-size `Row` to `Wrap` with `BoxConstraints(minWidth: 110, maxWidth: 275)`, `FittedBox(scaleDown)`, and `maxLines: 2`
- Google Sign-In button was missing on desktop layout of `WelcomeScreen` — added "Đăng nhập" nav button and inline guest login
- `backend/progress/src/handlers.rs`: `update_progress` now rejects invalid UUIDs (was silently generating random users)
- **Flutter `use_build_context_synchronously` lint fixed** — added `if (!mounted) return;` after `await` in `welcome_screen.dart` lines 417 and 419, preventing potential crashes from using `BuildContext` on a disposed widget
- **Rust `workspace.dev-dependencies` warning fixed** — removed invalid `[workspace.dev-dependencies]` key from `backend/Cargo.toml`; dev-dependencies are managed per-crate
- Removed duplicate `ProgressModel::update` method call in `progress/src/handlers.rs` (merged into single `upsert` call)
- Fixed `ProgressModel::update` SQL to also update `updated_at` field
- **Backend:** Fixed invalid `anyhow` macro usage in `user` service by replacing `bail!` with `return Err(...)` and using `map_err` for error handling.
- **Backend:** Resolved potential panic in `content` service's `get_lesson` by mapping internal errors to HTTP 500 responses.
- **Backend:** Replaced temporary `unwrap()` calls with proper error handling (using `ApiResponse::err`) in `auth`, `user`, `progress`, and `content` handlers.
- **Backend:** Removed unused imports and variables in Rust services to satisfy Clippy linting.
- **Frontend:** Fixed `analysis_options.yaml` to temporarily ignore `invalid_null_aware_operator` in generated files pending proper null-safety migration.
- **Frontend:** Ensured `google_sign_in` web configuration checks for `kIsWeb` before accessing `Platform` properties to avoid runtime exceptions.

### Removed
- `GET /api/progress` (unscoped endpoint that leaked all users' data)
- **Duplicate BktState**: merged methods from `engine/bkt.rs` into `models.rs::BktState`
- **Home screen unused variable**: removed unused `l10n` in `_buildDesktopNav`

## [2024-05-02] — i18n Feature Complete

### Added
- Full internationalization (vi/en) across all 7 screens
- 64 ARB localization keys
- `LanguageSwitcher` widget with persistence
- `make deploy` passes fully

## [Earlier]

- Initial Flutter + Rust microservices architecture
- Auth, User, Content, Progress, Notification, Media services
- Traefik reverse proxy + Docker Compose setup
- MinIO media storage
- Persona-based onboarding (Achiever, Gamer, Struggler, Silent)
- Parent dashboard with PIN gate
