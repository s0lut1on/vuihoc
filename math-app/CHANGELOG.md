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

### [Earlier changes]
...

---
**Note:** The canonical CHANGELOG lives at `docs/math-app/CHANGELOG.md`.
This file is mirrored for the `make deploy` gate.
