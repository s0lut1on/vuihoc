# Subject & Curriculum

Lessons are organized under subjects. Math subjects are served by `content-service`; Vietnamese and English are served by `language-service` with sub-subjects.

## Files

- `math-app/frontend/lib/screens/subject_screen.dart`
- `math-app/frontend/lib/services/content_api.dart`
- `math-app/frontend/lib/services/language_api.dart`
- `math-app/frontend/lib/models/lesson_model.dart`
- `math-app/backend/content/src/handlers.rs`
- `math-app/backend/content/src/models.rs`

## Subjects

| ID | Name (VI) | Name (EN) | Grade min | Service |
|---|---|---|---|---|
| numbers | Số học | Numbers | 1 | content |
| geometry | Hình học | Geometry | 1 | content |
| measurement | Đo lường | Measurement | 1 | content |
| logic | Tư duy | Logic | 1 | content |
| algebra | Đại số | Algebra | 2 | content |
| trigonometry | Lượng giác | Trigonometry | 3 | content |
| statistics | Thống kê | Statistics | 4 | content |
| vietnamese | Tiếng Việt | Vietnamese | 1 | language |
| english | Tiếng Anh | English | 1 | language |

## Math Subjects

- `subject_screen.dart` calls `ContentApi.getSubjectLessons(subjectId, grade)`.
- Lessons are sorted by `order`.
- A lesson is unlocked if it is the first lesson or the previous lesson is completed (`userProgressProvider`).
- Tapping a lesson routes to `/lesson/:subjectId/:lessonId`.

## Language Subjects

- Language subjects have an additional sub-subject grouping.
- `/subject/:subjectId` shows sub-subjects with unlock/completion progress from `LanguageApi.getDetailedProgress`.
- `/subject/:subjectId/:subSubjectId` shows the lessons inside that sub-subject.
- Tapping a lesson routes to `/language-lesson/:subjectId/:lessonId`.

## Unlock Animations

- When a new sub-subject becomes unlocked, `UnlockAnimationOverlay` plays a theme-matched animation (jungle, space, farm, ocean, castle).
- Parents can disable these animations from the parent dashboard.

## Performance

- The app avoids fetching the full 808KB curriculum. Each subject loads only its own lessons (~90KB) via lightweight endpoints.
