# Review Wrong Answers

When a child answers incorrectly, the app records the exercise so they can review it later. A dedicated review session pulls those exercises back for practice.

## Files

- `math-app/frontend/lib/services/review_api.dart`
- `math-app/frontend/lib/services/wrong_answer_storage.dart`
- `math-app/frontend/lib/screens/review_screen.dart`
- `math-app/frontend/lib/screens/home_screen.dart`
- `math-app/frontend/lib/services/progress_api.dart`
- `math-app/backend/question_bank/src/handlers.rs`

## Recording Wrong Answers

- Math lesson: `WrongAnswerStorage.record()` stores locally; if signed in, `ReviewApi.recordWrong()` sends to `/api/questions/review/:user_id`.
- Language lesson: per-exercise results are sent to `/api/progress/review`.

## Review Card

- `HomeScreen` fetches `ReviewApi.getWrongAnswerCount(userId)`.
- If > 0, a "Ôn tập lỗi" card appears above the continue card.

## Review Session

- `/review` loads exercises from `ProgressApi.getReviewSession(userId)`.
- Each exercise is rendered via `ExerciseDispatcher`.
- On a correct answer, `ProgressApi.submitExerciseResult(...isCorrect: true)` updates stats.
- After the last correct answer, the user returns home.

## Clearing

- `ReviewApi.clearWrong(userId, exerciseId)` calls `DELETE /api/questions/review/:user_id/:exercise_id`.
