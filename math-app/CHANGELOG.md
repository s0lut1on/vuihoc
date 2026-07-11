## [Unreleased]

### Added
- **HocVui Marketing Site (sekklings.com)** — full SEO rebuild with marketing site at root + Flutter app at `/app/`
  - **Marketing site (Astro + Tailwind)**: 240+ bilingual HTML pages (vi + en) at the root, including:
    - Landing pages (`/`, `/en`) with hero, features, stats, FAQ JSON-LD
    - Lessons catalog (`/lessons`, `/en/lessons`) — 20 subjects × 12 grades
    - Per-subject pages (`/lessons/{subject}`, `/en/lessons/{subject}`) with outcomes
    - Per-cell pages (`/lessons/{subject}/{grade}`, `/en/lessons/{subject}/{grade}`) with 800+ words of unique content, 7 learning outcomes, 6 exercise types, 6 sample lesson titles, parent tips, peer grades, cross-subject links, `Course` + `LearningResource` JSON-LD
    - Personas (`/personas`, `/en/personas`), pricing, parents FAQ, about, privacy, terms, 404
    - Blog infrastructure: content collections, `/blog` + `/blog/[slug]` + `/blog/rss.xml` (and EN equivalents), 1 sample post
    - Newsletter page (`/newsletter`, `/en/newsletter`) + Buttondown embed form on 4 high-traffic spots
    - Robots.txt (with AI-bot blocks), security.txt, `.well-known/security.txt`
  - **Full SEO surface** on every page: title, meta description, OpenGraph (vi_VN / en_US), Twitter card, canonical URL, hreflang (vi/en/x-default), JSON-LD blocks (Organization, WebSite, SoftwareApplication, FAQPage, Course, LearningResource, BreadcrumbList, BlogPosting), theme-color, manifest
  - **92 per-lesson OG images** (1200×630, ~35KB each) — one per (subject, grade) cell, branded with subject icon + name + lesson count
  - **RSS feeds** at `/blog/rss.xml` + `/en/blog/rss.xml`
  - **Branded assets**: 13 files (favicon, og-image-vi, og-image-en, icon-192/512, maskable variants, apple-touch-icon, logo SVG)

- **Self-hosted Umami analytics** — cookie-free, GDPR-friendly
  - New `umami` + `umami-db` services in `docker-compose.prod.yml`
  - Traefik router: `Host(sekklings.com) && PathPrefix(/umami)` with `stripprefix` middleware
  - Tracking script injected in marketing site BaseLayout + Flutter web index.html
  - Website id: `2153c8a8-f486-4b72-9284-332c036d1c16` (env var `PUBLIC_UMAMI_WEBSITE_ID`)
  - Admin password changed from default (see `marketing-site/docs/SEO_OPS.md`)

- **Traefik routing overhaul** — three priority tiers
  - Flutter web now at `/app/*` (priority 50, `stripprefix` strips `/app` before forwarding)
  - API services at `/api/*` (priority 100, existing)
  - Marketing site at root (priority 10, catches everything else)
  - New `www-redirect` service redirects `www.sekklings.com` → apex (SEO canonical)
  - Marketing site uses `bind mount` (not named volume) for dist/ — simpler deploys
  - Compose files updated: `docker-compose.prod.yml`, `docker-compose.ghcr.yml`, `docker-compose.yml`

- **Flutter web SEO** — branded shell
  - `web/index.html` rewritten with HocVui title, description, OG tags, theme-color, manifest, Umami script
  - `web/manifest.json` updated: HocVui name, scope=`/app/`, theme color, branded icons
  - `<base href="/app/">` set so Flutter app loads assets from `/app/...`
  - `<meta name="robots" content="noindex,nofollow">` on the SPA shell to avoid duplicate content

- **SEO toolchain** — repeatable deploy + monitoring
  - `scripts/deploy-marketing.sh` — build + rsync + restart + smoke test
  - `scripts/purge-cloudflare.sh` — Cloudflare API cache purge
  - `scripts/gen_brand_assets.py` — regenerate all 13 brand assets from `app_colors.dart`
  - `scripts/gen_lesson_og.py` — regenerate all 92 per-lesson OG images
  - `scripts/fetch_lessons.py` + `scripts/enrich_lessons.py` + `scripts/gen_subject_content.py` — build-time data pipeline
  - `marketing-site/docs/WRITING_BLOG.md` — guide for blog content (10 proposed post titles + keyword targets)
  - `marketing-site/docs/SEO_OPS.md` — operational runbook (Cloudflare, GSC, Umami, deploy)
  - `docs/PLAN_HOCVUI_SEO.md` — full 5-phase plan, all decisions locked

- **Pricing — single source of truth (Phase A of `docs/PLAN_PRICING_AND_BANNER.md`)**
  - New `math-app/pricing.json` — canonical pricing data (3 tiers, 14 features, 7 compare rows), vi + en strings, versioned
  - New `math-app/scripts/validate_pricing.py` — build-time schema validator; fails the marketing-site prebuild + Flutter build on bad data
  - `marketing-site/src/pages/pricing.astro` refactored to import `pricing.json` (3 tiers now visible: Free / Premium monthly / Premium yearly with 17% savings)
  - `marketing-site/package.json` — prebuild runs `npm run validate:pricing` before `fetch_lessons`
  - `frontend/assets/pricing.json` — generated copy (gitignored), bundled into Flutter web at build time via `pubspec.yaml`
  - `frontend/scripts/sync_pricing.sh` — keeps the asset in sync with the canonical source; called by `make build-web`
  - `frontend/lib/data/pricing.dart` — typed accessors (`PricingConfig.instance`, `tiers`, `tierById`, `featureText`, `tierName`, `pricePeriod`, `formatPrice`, `contactEmail`)
  - `frontend/lib/main.dart` — calls `PricingConfig.load()` at startup
  - `frontend/lib/screens/pricing_screen.dart` — refactored to read from `PricingConfig`, renders locale-aware (vi by default, en when app locale is en); tier cards + 7-row compare table + mailto CTA
  - `Makefile` — new targets `validate-pricing`, `sync-pricing`; `build-web` runs `sync_pricing.sh` first
  - `.gitignore` — excludes `frontend/assets/pricing.json` (regenerated each build)

### Changed
- **Course content**: padded every (subject, grade) cell to ≥ 50 lessons via migration 012_pad_to_50.sql
  - Migration applied live on VPS (no down time)
  - 4,125 → 6,060 lessons total (4,600 in the active catalog, 50 per cell × 92 cells)
  - 0 cells under 50; all 91 active cells ≥ 50
- **Docker compose files**: `Host(\`sekklings.com\`)` added to all routers in prod + ghcr; dev keeps `Host(\`localhost\`)`
- **Marketing site** moved from project root to `math-app/marketing-site/` (gets included in deploy-vps.sh rsync)

### Removed
- Old `docker-compose.marketing.yml` overlay (rolled into base compose files)

### Fixed
- `cloudflare cache` was serving stale `A new Flutter project` shell HTML — now served marketing site
- `favicon.ico` was 404 — now served from `/brand/favicon.ico`
- `<title>` was `math_app` — now `HocVui — Toán vui cho bé 5–7 tuổi`
- `<meta description>` was `A new Flutter project.` — now full Vietnamese description
- Vietnamese translations missing for many EN pages — now have full vi+en parity on lessons/personas/pricing/parents/about/blog


- **Language Subjects — Vietnamese & English** — new `language-service` backend + frontend widgets
  - New Python FastAPI service (`backend/language/`) with PostgreSQL `language_db`
  - Curriculum endpoints: `GET /api/language/curriculum`, `GET /api/language/lesson/:id`
  - Text validation endpoint: `POST /api/language/validate` — diacritic-aware (`exact`/`contains`/`levenshtein`)
  - TTS pipeline: `POST /api/language/audio/tts` — gTTS → MinIO bucket `audio-files` → public URL
  - Seed data: `seed_vietnamese.sql` (40 lessons) + `seed_english.sql` (40 lessons), exercise types `typing` + `audio_mcq`
  - Speech evaluation (`POST /api/language/speech/evaluate`) returns **501** — deferred to Phase 2 per user request
  - Frontend: `AudioPlayerWidget` (network audio + TTS fallback), `TextInputWidget` (typing with validation), `ExerciseDispatcherWidget` (routes `mcq`/`audio_mcq`/`typing`)
  - New screen: `LanguageLessonScreen` — progress bar, hint, celebration navigation
  - New subjects added to `HomeScreen` (`🇻🇳 Vietnamese`, `🇬🇧 English`) and `SubjectScreen` with routing
  - New route: `/language-lesson/:subjectId/:lessonId` in `AppRouter`
  - i18n: `parentDashboardSubjectVietnamese`, `parentDashboardSubjectEnglish` (vi + en)
  - `ApiService` supports `withBaseUrl('/api/language')` for multi-service auth sharing

- **Achievement/Badge System (#2)** — gamification with 6 badges earned automatically
  - New DB tables: `badge_definitions` (seeded with 6 badges), `achievements` (user badges earned)
  - New `GET /api/progress/achievements/:user_id` endpoint — returns all definitions with earned status
  - New `POST /api/progress/achievements/:user_id/:badge_type/mark-read` endpoint — clears `is_new` flag
  - `update_progress` now auto-checks thresholds after each completed lesson and inserts new achievements
  - 6 badges: `first_lesson`, `streak_3`, `streak_7`, `streak_30`, `star_collector_10`, `star_collector_50`

- **Leaderboard (#5)** — classroom-based peer competition
  - New DB migration: `users.classroom_code` (optional 6-char string)
  - New `POST /api/users/classroom/join` endpoint — sets active user's classroom_code (JWT-gated)
  - New `POST /api/users/classroom/leave` endpoint — clears classroom_code
  - New `GET /api/users/classroom/leaderboard` endpoint — top 10 by weekly stars in same classroom
  - `Users` model updated with `email`, `locale`, `subscription_tier`, `classroom_code` fields
  - New models: `JoinClassroomRequest`, `LeaderboardEntry`

- **Grade 4 & Grade 5 curriculum + new `statistics` (Thống kê) subject**
  - Bumps subject grade range from `1-3` → `1-5` across all existing subjects (numbers, geometry, measurement, logic, algebra, trigonometry, vietnamese, english)
  - New subject `statistics` (📊, grade 4-5) — `INSERT INTO subjects` + 60 lessons (10 topics × 3 lessons × 2 grades)
  - 540 new math lessons: 9 subjects × 2 grades × 30 lessons each (10 topics × 3 per topic)
  - 120 new language lessons: 2 subjects × 2 grades × 30 lessons (Vietnamese + English)
  - Backend: `user/handlers.rs::update_grade` clamps input to `1..=5` (was unbounded)
  - Frontend: grade chips `1-5` in `WelcomeScreen` + `ProfileScreen`; new `statistics` tile added to `HomeScreen` subjects grid (grade 4+)

- **Algebra + Trigonometry subjects** (grade 2+, grade 3+)
  - New subject `algebra` (🅰️, grade 2-5): 25 lessons — variables, simple equations, two-step equations, factoring, polynomial expressions, linear graphs
  - New subject `trigonometry` (📐, grade 3-5): 10 lessons — right triangle basics, Pythagorean theorem, sin/cos/tan, 30-60-90 / 45-45-90 triangles
  - Visible on `HomeScreen` subject grid; lessons load via existing `/subject/:id` route

- **HomeScreen unlocks subjects when grade changes** (#6)
  - Subjects grid now re-queries when user changes grade in profile/welcome
  - Filters `subjects` by current user's `grade` (`grade_min`..=`grade_max`)

- **bust-flutter-cache.sh** — 3-layer Flutter web cache invalidation
  - Dockerfile `sed` timestamp bump on `main.dart.js` / `flutter_bootstrap.js`
  - NGINX `Cache-Control: no-cache` headers
  - Flutter SW-unregister script in `index.html`
  - Diagnoses stale deploys: `curl https://HOST/main.dart.js | grep HocVui <sha>`

- **Content migration fixes**
  - `0710b21` — share migration-003 lessons across all grades (was pinned to grade 1)
  - `ceda4eb` — share seed language lessons across all grades
  - `d3fffd1` — HomeScreen subject list reflects new grade after grade change

### [Earlier changes]
...

---
**Note:** The canonical CHANGELOG lives at `docs/math-app/CHANGELOG.md`.
This file is mirrored for the `make deploy` gate.
