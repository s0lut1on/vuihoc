# Spaced Repetition / Review Scheduling

The backend schedules review exercises using a spaced-repetition-like algorithm so children revisit concepts they struggled with at optimal intervals.

## Files

- `math-app/backend/progress/src/spaced_repetition.rs`
- `math-app/backend/progress/src/handlers.rs`
- `math-app/backend/progress/src/models.rs`
- `math-app/frontend/lib/screens/review_screen.dart`

## Algorithm

- Each wrong answer increments the exercise's wrong count.
- The review session endpoint selects exercises that are due for review based on wrong count, last review time, and an interval function.
- Correct answers during review reduce the wrong count or remove the exercise from the review queue.

## Review Session API

- `GET /api/progress/review/:user_id` returns `{ exercises: [...] }`.
- `POST /api/progress/review` submits `{ user_id, exercise_id, lesson_id, is_correct }`.

## Frontend

- `ReviewScreen` renders returned exercises via `ExerciseDispatcher`.
- Progress bar shows position in the review session.
