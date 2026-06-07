# Plan: Peer / Sibling Leaderboard (Anonymous)

## Problem
Kids lack competitive motivation. Leaderboards risk exposing PII if not designed carefully.

## Goal
Show anonymous percentile rankings per grade level to motivate without exposing names or exact scores.

## Scope

### MVP (2-3 days)
- **Backend**: Add `leaderboard` materialized view or Redis sorted set in `progress-service`:
  - Key pattern: `leaderboard:{subject_id}:{grade}:{week}`
  - Score: total correct answers in current week.
  - Member: `user_id` (hashed for privacy).
- **Backend**: New endpoint `GET /api/progress/leaderboard?subject_id=X&grade=Y`:
  - Returns:
    - User's percentile (e.g., "Top 15%")
    - Anonymous top-5 bracket (e.g., "A student completed 142 exercises this week")
  - No names, no avatars, no exact user IDs.
- **Frontend**: Add "This Week" card to `SubjectScreen` or `HomeScreen`:
  - "You are in the top 23% of Grade 1 English learners this week!"
  - Fire icon animation for top 10%.

### V2
- Sibling-only leaderboard (requires parent to link multiple child accounts under one parent_id).
- Monthly leaderboard with badge rewards.

## Affected Files

### Backend
- `math-app/backend/progress/src/db.rs` — leaderboard schema / Redis sorted set helpers
- `math-app/backend/progress/src/router.rs` — `/leaderboard` route
- `math-app/backend/progress/src/handlers.rs` — percentile calc + top-5 anonymous bracket
- `math-app/backend/progress/src/scheduler.rs` — new, weekly Redis key rotation

### Frontend
- `math-app/frontend/lib/screens/subject_screen.dart` — leaderboard card
- `math-app/frontend/lib/screens/home_screen.dart` — weekly summary badge
- `math-app/frontend/lib/services/progress_api.dart` — add `getLeaderboard()`
- `math-app/frontend/lib/models/` — add `Leaderboard` model

## Effort Estimate
- **Backend**: 1.5 days (Redis sorted sets + percentile math + scheduler)
- **Frontend**: 1 day (card UI + animation)
- **Testing**: 0.5 day

## Risks
- Redis memory: sorted sets per subject × grade × week could grow. Cap at 4 weeks of history, TTL 30 days.
- Privacy: never return raw user_id in leaderboard; hash with daily salt.
- Tie-breaking: if two users have same score, randomize order or use timestamp.

## Success Criteria
- [ ] User sees "Top 23%" after completing 10 exercises in a week.
- [ ] Leaderboard response contains no PII (no names, emails, raw user_ids).
- [ ] Redis keys auto-expire after 30 days.
