# Plan: Spaced Repetition + Weak Spot Drill

## Problem
Users practice exercises linearly by lesson, but weak areas (exercises they get wrong repeatedly) are not revisited automatically. Mastery decays without review.

## Goal
Implement a spaced-repetition engine that:
1. Tracks per-exercise accuracy per user.
2. Auto-generates a "Review" daily session of weak items.
3. Schedules reviews at increasing intervals (1d, 3d, 7d, 14d, 30d).

## Scope

### MVP (Week 1)
- **Backend**: Add `user_exercise_stats` table in `progress-db`:
  ```sql
  CREATE TABLE user_exercise_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    exercise_id UUID REFERENCES language_exercises(id),
    correct_count INT DEFAULT 0,
    wrong_count INT DEFAULT 0,
    last_seen_at TIMESTAMPTZ,
    next_review_at TIMESTAMPTZ,
    interval_days INT DEFAULT 1,
    ease_factor FLOAT DEFAULT 2.5, -- SM-2 style
    UNIQUE(user_id, exercise_id)
  );
  ```
- **Backend**: New endpoint `POST /api/progress/review-session`:
  - Input: `user_id`, `subject_id` (optional)
  - Output: 5-10 exercises due for review, sorted by `next_review_at` ascending.
- **Backend**: Hook into `POST /api/progress/submit`:
  - After every submission, update `correct_count`/`wrong_count`, recalc `ease_factor`, bump `interval_days`, set `next_review_at = now() + interval_days`.
- **Frontend**: New screen `ReviewSessionScreen` (reuses existing exercise widgets — `mcq`, `typing`, `matching`, etc.).
- **Frontend**: Add "Review" card to `SubjectScreen` or `HomeScreen` when `next_review_at` exercises exist (badge count).

### V2 (Week 2)
- Adaptive interval algorithm: if user gets 3 correct in a row, double interval; if wrong, reset to 1d.
- Push notification: "You have 5 reviews waiting" via `notification-service`.

## Affected Files

### Backend
- `math-app/backend/progress/src/db.rs` — add `user_exercise_stats` schema + queries
- `math-app/backend/progress/src/router.rs` — add `/review-session` route
- `math-app/backend/progress/src/handlers.rs` — implement review session builder + SM-2 update logic
- `math-app/backend/language/src/router/progress.py` — or keep in progress-service; decide boundary
- `math-app/backend/language/migrations/` — add migration `009_user_exercise_stats.sql`

### Frontend
- `math-app/frontend/lib/screens/review_session_screen.dart` — new
- `math-app/frontend/lib/screens/home_screen.dart` — add Review badge/card
- `math-app/frontend/lib/services/progress_api.dart` — add `getReviewSession()`, `submitReviewResult()`
- `math-app/frontend/lib/models/` — add `ReviewExercise` model

## Effort Estimate
- **Backend**: 2 days (schema + endpoint + SM-2 logic)
- **Frontend**: 1 day (screen reuses widgets, badge is small)
- **Testing**: 0.5 day

## Risks
- Must not conflict with existing `user_progress` table logic.
- SM-2 math is simple but needs careful float handling.

## Success Criteria
- [ ] User gets a review session with 5 exercises when `wrong_count >= 2` and `next_review_at <= now()`.
- [ ] After 3 correct reviews, interval reaches 7d.
- [ ] No duplicate reviews in same day.
