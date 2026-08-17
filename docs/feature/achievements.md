# Achievements

Achievement badges reward learning milestones (lessons completed, stars earned, streaks, etc.). New badges are surfaced on the celebration screen.

## Files

- `math-app/frontend/lib/services/achievement_service.dart`
- `math-app/frontend/lib/screens/celebration_screen.dart`
- `math-app/frontend/lib/screens/achievement_screen.dart`
- `math-app/frontend/lib/models/achievement_model.dart`
- `math-app/backend/progress/src/handlers.rs`

## API

- `GET /api/progress/achievements/:user_id` — list achievements.
- `POST /api/progress/achievements/:user_id/:badge_type/mark-read` — mark a badge as read.

## Frontend Flow

1. `CelebrationScreen._checkNewBadges()` fetches achievements after a lesson is completed.
2. Badges with `isNew == true` are shown in a popup.
3. Tapping "Tuyệt vời!" marks the badges as read.

## Achievement Screen

- Lists all badges and their states.
- Accessible from the home screen menu and nav bar.
