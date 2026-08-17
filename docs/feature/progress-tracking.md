# Progress Tracking

Progress records which lessons a user has completed and how many stars they earned. It drives lesson unlocking, home-screen stats, and parent reports.

## Files

- `math-app/frontend/lib/services/progress_api.dart`
- `math-app/frontend/lib/services/language_api.dart`
- `math-app/frontend/lib/providers/app_providers.dart`
- `math-app/backend/progress/src/handlers.rs`
- `math-app/backend/progress/src/models.rs`

## Data Model

A progress row contains:

- `user_id`
- `lesson_id`
- `completed` (bool)
- `stars` (int, 1–3)
- `attempts`
- `updated_at`

## APIs

- `GET /api/progress/:user_id` — all progress rows.
- `POST /api/progress` — update a single lesson.
- `POST /api/progress/batch` — batch update (used by offline sync).
- `POST /api/progress/review` — submit per-exercise result for review stats.
- `GET /api/progress/review/:user_id` — review session exercises.
- `GET /api/progress/daily-limit/:user_id` — daily lesson count + tier.
- `GET /api/progress/streak/:user_id` — streak data.
- `GET /api/progress/achievements/:user_id` — achievement badges.

## Frontend Providers

- `rawProgressProvider` — all progress rows.
- `userProgressProvider` — set of completed `lesson_id`s.
- `totalStarsProvider` — sum of stars.
- `streakProvider` — streak from backend.
- `dailyLimitProvider` — count + tier.

## Lesson Unlocking

In the subject screen, a lesson is unlocked if it is the first lesson or the previous lesson in order is completed.
