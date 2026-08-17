# Lesson & Exercises

The lesson screen presents one exercise at a time. Each lesson contains multiple exercises with multiple-choice options, hints, and immediate feedback.

## Files

- `math-app/frontend/lib/screens/lesson_screen.dart`
- `math-app/frontend/lib/screens/language_lesson_screen.dart`
- `math-app/frontend/lib/widgets/exercise_dispatcher.dart`
- `math-app/frontend/lib/services/content_api.dart`
- `math-app/frontend/lib/services/language_api.dart`
- `math-app/frontend/lib/services/progress_api.dart`
- `math-app/frontend/lib/services/question_bank_api.dart`

## Math Lesson Flow (`LessonScreen`)

1. Loads a single lesson via `ContentApi.getLesson(lessonId)`.
2. Renders the current question with a visual asset.
3. Tapping an option:
   - Correct: green highlight, haptic feedback, auto-advance after 800ms.
   - Wrong: red highlight, shows hint, records wrong answer locally and on the backend.
4. Wrong answers can be retried via the reset button.
5. On completion, `ProgressApi.updateProgress` is called and the celebration screen opens.

## Language Lesson Flow (`LanguageLessonScreen`)

1. Loads a lesson via `LanguageApi.getLesson(lessonId)`.
2. Uses `ExerciseDispatcher` to support typed, audio, and multiple-choice exercise types.
3. After 2 wrong attempts, fetches an AI-generated hint via `QuestionBankApi.getHint`.
4. Stars are computed from accuracy (1–3 stars) and progress is sent to `language-service`.

## Visual Assets

- Visual assets are strings attached to exercises.
- `ClockFace.tryParse(asset)` renders an analog clock when the asset matches `clock|hour|minute`.
- Other assets are rendered as large emoji/text.

## Worksheet Button

- Each math lesson has a worksheet button that opens `/api/content/lesson/:lessonId/worksheet` in an external browser tab.
