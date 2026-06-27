## [Unreleased]

### Added
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
