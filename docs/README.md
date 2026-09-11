# HocVui — Toán vui cho bé 5–7 tuổi

A bilingual (Vietnamese + English) math learning platform for kids ages 5–7, built with **Flutter** (frontend) and **Rust microservices** (backend).

**Live site:** [sekklings.com](https://sekklings.com) · **App:** [sekklings.com/app](https://sekklings.com/app)

## Quick Start

```bash
cd math-app
make setup    # Install dependencies
make deploy   # Full CI pipeline (format, lint, test, build, e2e)
```

## Deploy to VPS

```bash
cd math-app
make deploy-vps          # full: sync source + build + restart + health check
make deploy-vps-status   # show running containers + version
make deploy-vps-logs SERVICES=auth-service   # tail logs
```

See [docs/math-app/VPS_DEPLOY.md](docs/math-app/VPS_DEPLOY.md) for detailed deploy instructions.

## Project Layout

```
.
├── math-app/               # Main application
│   ├── frontend/           # Flutter app (Dart, Riverpod, GoRouter)
│   ├── backend/            # Rust microservices (Axum, SQLx)
│   │   ├── auth/           # JWT auth + Google Sign-In + Guest
│   │   ├── user/           # User profiles, classroom, leaderboard
│   │   ├── content/        # Curriculum, lessons, exercises
│   │   ├── progress/       # Progress tracking, streaks, badges, daily limits
│   │   ├── notification/   # Push notifications
│   │   ├── media/          # MinIO storage
│   │   ├── question_bank/  # Parametric question generation + BKT
│   │   ├── payment/        # Stripe checkout + subscriptions
│   │   ├── shared/         # Shared types (Claims, CORS, etc.)
│   │   └── language/       # Python FastAPI — Vietnamese/English language lessons
│   ├── marketing-site/     # Astro + Tailwind — sekklings.com marketing site
│   ├── e2e/                # Playwright E2E tests
│   ├── pricing.json        # Canonical pricing data (single source of truth)
│   └── Makefile            # Dev + deploy commands
│
├── docs/                   # All documentation
│   ├── math-app/           # App-specific docs (architecture, plans, codemaps)
│   ├── feature/            # Feature design docs
│   ├── incoming/           # Backlog / proposed features
│   ├── CHANGELOG.md        # Full changelog (canonical)
│   ├── FEATURE_IDEAS.md    # Roadmap suggestions for growth
│   ├── PROJECT_ISSUES_AUDIT.md  # Security + code quality audit
│   ├── PLAN_HOCVUI_SEO.md  # SEO strategy plan
│   ├── PLAN_PRICING_AND_BANNER.md  # Pricing + paywall design
│   └── ...                 # See docs/README.md for full index
│
├── CHANGELOG.md            # Recent changes (mirrors docs/math-app/CHANGELOG.md)
└── README.md               # This file
```

## Key Features

- **6,000+ Lessons** across Numbers, Geometry, Measurement, Logic, Algebra, Trigonometry, Statistics
- **Language Subjects** — Vietnamese + English with TTS and diacritic-aware validation
- **Persona-based Onboarding** — 4 learning personas adapt tone and encouragement
- **Bilingual UI** — Vietnamese + English with toggle on every screen
- **Adaptive Questions** — Parametric generation + Bayesian Knowledge Tracing (BKT)
- **Parent Dashboard** — PIN-gated progress overview
- **Achievement System** — 6 auto-earned badges (streaks, stars, first lesson)
- **Leaderboard** — Classroom-based peer competition
- **Google Sign-In + Guest Login** — Multiple auth methods with route guards
- **Free / Premium Tiers** — Free tier has unlimited lessons; Premium adds email reports, multi-child, CSV export, priority support (39K VND/month)
- **Marketing Site** — 240+ bilingual SEO pages with structured data, sitemap, OG images

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart), Riverpod, GoRouter, Hive |
| Backend | Axum (Rust), SQLx, utoipa (OpenAPI) |
| Language service | Python FastAPI, gTTS, MinIO |
| Databases | PostgreSQL (per service) |
| Storage | MinIO |
| Proxy | Traefik |
| Analytics | Self-hosted Umami |
| Marketing | Astro + Tailwind CSS |
| Testing | Flutter (179), Rust (173+94 ignored), Python (95), Playwright E2E |

## Documentation

All docs live in [`docs/`](docs/). Key entries:

- [docs/math-app/README.md](docs/math-app/README.md) — Architecture, API, setup guide
- [docs/math-app/VPS_DEPLOY.md](docs/math-app/VPS_DEPLOY.md) — VPS deploy runbook
- [docs/CHANGELOG.md](docs/math-app/CHANGELOG.md) — Full changelog
- [docs/FEATURE_IDEAS.md](docs/FEATURE_IDEAS.md) — Growth + feature roadmap
- [docs/PROJECT_ISSUES_AUDIT.md](docs/PROJECT_ISSUES_AUDIT.md) — Security audit (all fixed)
- [docs/PLAN_HOCVUI_SEO.md](docs/PLAN_HOCVUI_SEO.md) — SEO strategy
- [docs/PLAN_PRICING_AND_BANNER.md](docs/PLAN_PRICING_AND_BANNER.md) — Pricing design

## License

MIT