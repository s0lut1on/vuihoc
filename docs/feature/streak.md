# Streak

The streak feature tracks how many consecutive days the child has completed at least one lesson. It is shown on the home screen and in the profile.

## Files

- `math-app/frontend/lib/services/progress_api.dart`
- `math-app/frontend/lib/providers/app_providers.dart`
- `math-app/backend/progress/src/handlers.rs`
- `math-app/backend/progress/src/models.rs`

## API

- `GET /api/progress/streak/:user_id`
- Response includes `current_streak`.

## UI

- `HomeScreen` shows a `StreakBadge` in the nav bar and a `_StreakCard` in the stats row.
- `ProfileScreen` shows streak days in the stat cards.

## Update Flow

- Streak is updated by the backend when a lesson is completed.
- `streakProvider` is invalidated after language-lesson completion so the home screen refreshes.
