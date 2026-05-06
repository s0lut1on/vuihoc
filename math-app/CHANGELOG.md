# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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

### Fixed
- **Google user shows real avatar and name instead of "Khách"**
  - `currentUserProvider` now watches `authUserProvider` stream to auto-refetch after sign-in
  - `ProfileScreen` made null-safe for `AppLocalizations` access
- Answer box text overflow: `_buildOptions` in `lesson_screen.dart` changed from fixed-size `Row` to `Wrap` with `BoxConstraints(minWidth: 110, maxWidth: 275)`, `FittedBox(scaleDown)`, and `maxLines: 2`
- Google Sign-In button was missing on desktop layout of `WelcomeScreen` — added "Đăng nhập" nav button and inline guest login
- `backend/progress/src/handlers.rs`: `update_progress` now rejects invalid UUIDs (was silently generating random users)
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
