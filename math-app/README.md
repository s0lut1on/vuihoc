# Math App

Math learning Flutter app for Vietnamese kids ages 5-7 with Rust microservices backend.

## Quick Start

```bash
# Install dependencies (local Flutter SDK + Rust + Playwright)
make setup
make e2e-setup

# Full CI pipeline: format, lint, test, build
make deploy

# Start all services (Docker)
make docker-dev

# Run E2E tests against running services
make e2e-test
```

## Requirements

- **Docker with Buildx**
  - If `buildx` isn't installed, run:
    ```bash
    docker buildx create --use
    ```
- **Rust 1.93** (matching `backend/Dockerfile`)
- **Flutter** (optional: local SDK is auto-downloaded)
- **Node.js 18+** (for E2E tests)

## Access URLs

### After `make docker-dev`

| URL | Resource |
|-----|----------|
| [http://localhost:8082](http://localhost:8082) | Flutter web app |
| [http://localhost:8083](http://localhost:8083) | Traefik dashboard |

### API Docs (Swagger UI)

| Service | URL |
|---------|-----|
| Auth | http://localhost:8082/api/auth/swagger-ui |
| Content | http://localhost:8082/api/content/swagger-ui |
| Users | http://localhost:8082/api/users/swagger-ui |
| Progress | http://localhost:8082/api/progress/swagger-ui |
| Notifications | http://localhost:8082/api/notifications/swagger-ui |
| Media | http://localhost:8082/api/media/swagger-ui |
| **Question Bank** | http://localhost:8082/api/questions/swagger-ui |

### MinIO Console

| URL | Resource |
|-----|----------|
| [http://localhost:9002](http://localhost:9002) | MinIO API |
| [http://localhost:9003](http://localhost:9003) | MinIO Console |

## Makefile Commands

### Development

| Command | Description |
|---------|-------------|
| `make setup` | Install dependencies |
| `make deploy` | Full CI pipeline (format+lint+test+build) |
| `make lint` | Run analyzers |
| `make format` | Format code |
| `make clean` | Clean all build files |

### Testing

| Command | Description |
|---------|-------------|
| `make test` | Flutter tests only |
| `make test-rust` | Rust tests only |
| `make test-all` | All tests (Flutter + Rust) |
| `make e2e-setup` | Install Playwright + Chromium |
| `make e2e-test` | Run E2E tests (requires services running) |

### Building

| Command | Description |
|---------|-------------|
| `make build-web` | Build Flutter web |
| `make build-rust` | Build Rust backend |
| `make build-apk` | Build Android APK |

### Docker

| Command | Description |
|---------|-------------|
| `make docker-dev` | Start Docker services |
| `make docker-stop` | Stop Docker services |
| `make docker-test` | Run tests in Docker |

## Project Structure

```
.
├── frontend          # Flutter app
│   ├── lib/          # Screens, widgets, models, services
│   └── test/         # Widget + unit tests
├── backend           # Rust workspace
│   ├── auth/         # Auth microservice
│   ├── user/         # User microservice
│   ├── content/      # Content/curriculum microservice
│   ├── progress/     # Progress tracking microservice
│   ├── notification/ # Notification microservice
│   ├── media/        # Media/storage microservice
│   ├── question_bank/# Question bank + BKT microservice
│   └── shared/       # Shared types + utilities
├── e2e               # Playwright E2E tests
│   ├── tests/        # Test specs
│   └── playwright.config.ts
├── docker-compose.yml
├── Makefile
└── package.json
```

## Architecture

- **Frontend**: Flutter (Dart) with Riverpod state management, GoRouter navigation, i18n (vi/en)
- **Backend**: Axum (Rust) microservices with PostgreSQL, sqlx, utoipa (OpenAPI/Swagger)
- **Reverse Proxy**: Traefik routes `/api/*` to services
- **Storage**: MinIO for media, PostgreSQL per service
- **Question Engine**: Parametric question generation with Bayesian Knowledge Tracing (BKT)

## Testing

### Unit Tests
- **Flutter**: `make test` — widget tests, model tests
- **Rust**: `make test-rust` — unit + integration tests

### E2E Tests
- **Playwright**: `make e2e-test` — browser automation against deployed web app
- Auto-starts Docker services if not running
- Tests API health + page loads

## Features

### Learning Experience

| Feature | Description |
|---------|-------------|
| **Persona-based Onboarding** | 4 learning personas (Achiever, Gamer, Struggler, Silent) adapt tone and encouragement style |
| **Assessment Quiz** | 4-question adaptive assessment at onboarding to calibrate starting level |
| **Mass Curriculum** | 1,710+ lessons across 4 subjects: Numbers, Geometry, Measurement, Logic |
| **Dynamic Lesson Progression** | Lessons unlock sequentially — complete lesson N-1 to unlock lesson N within each subject |
| **Visual Lesson Status** | Subject screen shows locked 🔒, unlocked, or completed ✅ state per lesson |
| **Retry on Wrong Answer** | "Try again" button appears after incorrect answers; child can retry indefinitely |
| **Multi-Exercise Lessons** | Lessons contain 1-3 exercises answered in sequence before celebrating |
| **Celebration Screen** | Stars earned, gem rewards, persona-specific messages; "Next lesson" auto-advances |
| **Localized Content** | Every exercise has Vietnamese + English questions and hints |
| **Progress Tracking** | Backend tracks completed lessons, stars earned (1-3), and attempt counts |
| **Streak System** | Daily activity streaks with current/best streak tracking; resets if a day is missed |
| **Parent Dashboard** | PIN-gated dashboard showing lessons learned, stars earned, study streak, and subject progress |
| **Language Switcher** | 🇻🇳 Tiếng Việt / 🇬🇧 English toggle on every screen (desktop pill, mobile bottom sheet); persisted via Hive |
| **Responsive Design** | Dedicated mobile and desktop layouts for all screens |
| **Text-to-Speech** | 🔊 Speaker button reads question aloud |

### Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| **WelcomeScreen** | `/` | Persona selection, onboarding start |
| **AssessmentScreen** | `/assessment` | Adaptive level quiz |
| **HomeScreen** | `/home` | Subject grid, continue-learning card, stats, streak |
| **SubjectScreen** | `/subject/:subjectId` | Lesson list with lock/unlock/completed status |
| **LessonScreen** | `/lesson/:subjectId/:lessonId` | Interactive exercises with hints, retry, and next-question flow |
| **CelebrationScreen** | `/celebration` | Reward screen with stars and next-lesson navigation |
| **PinGateScreen** | `/parent-dashboard` | 4-digit PIN to access parent area |
| **ParentDashboardScreen** | `/parent-dashboard/main` | Child progress overview and settings |

### Backend Services

| Service | Tech | Purpose |
|---------|------|---------|
| **Auth** | Axum + JWT | Google OAuth login, token issuance |
| **User** | Axum + sqlx | User profiles, personas, locale preferences |
| **Content** | Axum + sqlx | Curriculum (1,710 lessons + 1,730 exercises), subjects, single-query JOIN fetch |
| **Progress** | Axum + sqlx | Lesson completion, stars, streak tracking, per-user progress API |
| **Question Bank** | Axum + MiniJinja + meval | Parametric math question generation, Bayesian Knowledge Tracing (BKT), distractor generation, error taxonomy |
| **Notification** | Axum + sqlx | Push notification records |
| **Media** | Axum + MinIO | Upload URLs, media asset management |
| **Shared** | Rust lib | ApiResponse, HealthResponse, pagination types |

### DevOps / QA

| Feature | Description |
|---------|-------------|
| **E2E Tests** | Playwright (18 tests): API health checks, page loads, navigation, responsive layout |
| **CI Pipeline** | `make deploy` = format → lint → changelog-check → Flutter tests → Rust tests → build web → build Rust → docker-dev → E2E tests |
| **Swagger UI** | OpenAPI docs for all 7 backend services at `/api/{service}/swagger-ui` |
| **Docker Compose** | All services + databases + Traefik + MinIO in one command |
| **Traefik** | Reverse proxy with automatic service discovery |
| **Nginx** | SPA routing (`try_files`) for Flutter web hash-based URLs |

## License

MIT
