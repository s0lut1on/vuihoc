# Plan: Daily Streak + Achievements

## Problem
No retention mechanics beyond lesson progression. Users who skip days have no reason to return.

## Goal
Add a lightweight daily streak counter and achievement badge system to drive retention.

## Scope

### MVP (3 days)
- **Backend**: Add `user_streaks` and `user_achievements` tables in `progress-db` (or new `gamification-db` if preferred).
  ```sql
  CREATE TABLE user_streaks (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    current_streak INT DEFAULT 0,
    longest_streak INT DEFAULT 0,
    last_activity_date DATE DEFAULT CURRENT_DATE
  );

  CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    achievement_key VARCHAR(64) NOT NULL,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, achievement_key)
  );

  CREATE TABLE achievements (
    key VARCHAR(64) PRIMARY KEY,
    title_vi VARCHAR(128),
    title_en VARCHAR(128),
    description_vi TEXT,
    description_en TEXT,
    icon VARCHAR(64), -- e.g., "trophy", "flame"
    condition_type VARCHAR(32), -- 'streak', 'count', 'perfect'
    condition_value INT
  );
  ```
- **Backend**: New endpoint `GET /api/progress/streak/{user_id}` — returns streak + achievements.
- **Backend**: Hook into `POST /api/progress/submit`:
  - If `last_activity_date != today`, update streak (break or increment).
  - Check achievement unlock conditions (e.g., `streak >= 7`, `correct_count >= 100`, `perfect_lesson_count >= 5`).
- **Frontend**: Add streak flame icon + count to `HomeScreen` app bar.
- **Frontend**: New screen `AchievementsScreen` — grid of locked/unlocked badges with progress bars.

### V2
- Streak freeze: allow 1 missed day per week without breaking streak.
- Push notification: "Your streak ends in 4 hours! Do a quick review."
- Weekly leader board among siblings (if parent links multiple kids).

## Affected Files

### Backend
- `math-app/backend/progress/src/db.rs` — streak + achievement schemas
- `math-app/backend/progress/src/router.rs` — `/streak/{user_id}` route
- `math-app/backend/progress/src/handlers.rs` — streak update + achievement evaluation
- `math-app/backend/progress/migrations/` — add migration `010_gamification.sql`

### Frontend
- `math-app/frontend/lib/screens/achievements_screen.dart` — new
- `math-app/frontend/lib/screens/home_screen.dart` — streak badge in app bar
- `math-app/frontend/lib/services/progress_api.dart` — add `getStreak()`, `getAchievements()`
- `math-app/frontend/lib/models/` — add `Streak`, `Achievement` models

## Effort Estimate
- **Backend**: 1 day (tables + hook + endpoint)
- **Frontend**: 1 day (badges screen + grid UI)
- **Testing**: 0.5 day

## Risks
- Date boundary handling (timezone): store all dates in UTC, display in local time.
- Achievement condition evaluation on every submit could be slow — batch or cache.

## Success Criteria
- [ ] User sees flame icon with "3" after 3 consecutive days of any activity.
- [ ] Achievement "7-Day Streak" unlocks automatically after 7 days.
- [ ] Missed day resets streak to 0.
