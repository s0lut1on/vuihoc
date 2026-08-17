# Plan: Adaptive Difficulty (BKT Integration)

## Problem
All students see the same exercises in the same order, regardless of skill level. A student who already knows addition sees easy problems (boredom). A struggling student gets stuck on hard problems (frustration). The BKT engine exists in `question-bank-service` but is NOT wired into the lesson flow.

## Goal
Use the existing Bayesian Knowledge Tracing (BKT) engine to dynamically select exercise difficulty per student. When a student demonstrates mastery at difficulty N, serve difficulty N+1. When they struggle, serve easier variants.

## Scope

### MVP — Backend (2-3 days)

**BKT wire-up in content-service**:

The content service fetches static exercises from DB. The question-bank service generates parametric questions with BKT state. Bridge them:

1. **New endpoint** `GET /api/content/lesson/:id/adaptive?user_id=:uid`:
   - Returns exercises for the lesson, but selects difficulty based on user's BKT mastery for the relevant Knowledge Component (KC)
   - Queries question-bank service for `p_mastery` of the student's KC
   - Maps `p_mastery` → difficulty level:
     - p < 0.3 → difficulty 1 (easy)
     - p < 0.5 → difficulty 2 (medium) 
     - p < 0.7 → difficulty 3 (hard)
     - p < 0.85 → difficulty 4 (harder)
     - p >= 0.85 → difficulty 5 (challenge)
   - Returns exercises filtered/tagged to that difficulty

2. **Exercise difficulty tagging**:
   - `exercises` table needs `difficulty` column (1-5)
   - Migration: `ALTER TABLE exercises ADD COLUMN difficulty INT NOT NULL DEFAULT 1;`
   - Backfill: map existing `correct_index` heuristics to difficulty
   - New exercises get difficulty set explicitly

3. **Post-answer BKT update hook**:
   - After `POST /api/progress` (lesson submit), also call `POST /api/questions/answer/:student_id` on question-bank service
   - This updates BKT `p_mastery` for the student's KC
   - Uses existing `question_bank/src/handlers.rs::submit_answer`

**Question-bank service improvements**:
- `GET /api/questions/mastery/:student_id/:kc_id` — already exists, returns `BktState`
- `POST /api/questions/answer/:student_id` — already exists, updates mastery
- Need to add: KC-to-lesson mapping table:
  ```sql
  CREATE TABLE lesson_kc_map (
    lesson_id VARCHAR(50) PRIMARY KEY REFERENCES lessons(id),
    kc_id UUID REFERENCES kc(id),
    importance FLOAT DEFAULT 1.0  -- how much this KC matters for this lesson
  );
  ```

### MVP — Frontend (1-2 days)

**Lesson screen changes** (`lesson_screen.dart`):
- Fetch lesson via new adaptive endpoint: `GET /api/content/lesson/:id/adaptive?user_id=:uid`
- Pass `user_id` and `lesson_id` in the request
- Exercises returned are already filtered to the student's level

**Progress hook**:
- After each exercise answer, call `POST /api/questions/answer/:student_id` 
- This runs in parallel with existing `POST /api/progress` call — no latency added

**KC provider**:
- New `FutureProvider` in `app_providers.dart`: `kcMasteryProvider`
- Caches BKT state per (user_id, kc_id)
- Invalidate on lesson completion

### V2
- Adaptive lesson ordering: suggest next lesson based on weakness (lowest `p_mastery`)
- Sub-subject mastery displayed in subject screen as progress bar
- "I'm bored" button → skip to harder exercises
- "Too hard" button → drop difficulty for rest of lesson

## Affected Files

### Backend
- `math-app/backend/content/src/handlers.rs` — add `get_adaptive_lesson()` handler
- `math-app/backend/content/src/main.rs` — add `/api/content/lesson/:id/adaptive` route
- `math-app/backend/content/src/models.rs` — add `difficulty` to Exercise
- `math-app/backend/content/migrations/` — add `014_exercise_difficulty.sql`, `015_lesson_kc_map.sql`
- `math-app/backend/question_bank/src/handlers.rs` — ensure KC lookup works per lesson
- `math-app/backend/question_bank/src/models.rs` — add `LessonKcMap`

### Frontend
- `math-app/frontend/lib/screens/lesson_screen.dart` — use adaptive endpoint
- `math-app/frontend/lib/services/content_api.dart` — add `getAdaptiveLesson()`
- `math-app/frontend/lib/providers/app_providers.dart` — add `kcMasteryProvider`
- `math-app/frontend/lib/services/progress_api.dart` — add BKT submit on exercise answer

## Effort Estimate
- **Backend**: 2-3 days (difficulty tagging, KC mapping, adaptive endpoint)
- **Frontend**: 1-2 days (adaptive lesson fetch, BKT hook)
- **Testing**: 1 day
- **Total**: ~5 days

## Risks
- BKT params (p_learn, p_slip, p_guess) need tuning per KC. Start with defaults (0.2, 0.1, 0.2).
- Difficulty 5 exercises must exist in DB for each lesson — seed if missing.
- Adaptive lesson may confuse parents expecting linear progression. Show difficulty badge.

## Success Criteria
- [ ] Exercise difficulty adapts to student's BKT mastery within a lesson
- [ ] Strong student sees difficulty 4-5 exercises first
- [ ] Struggling student sees difficulty 1-2 exercises
- [ ] BKT state updates after every exercise answer
- [ ] Difficulty badge visible on each exercise card
- [ ] Fallback to static exercises if BKT state unavailable
