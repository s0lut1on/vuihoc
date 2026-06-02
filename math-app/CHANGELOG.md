## [Unreleased]

### Added
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