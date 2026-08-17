# Grade System

Grade is a per-user setting (1–12) that determines which subjects and lessons are shown. Higher grades unlock more advanced subject tiles on the home screen.

## Files

- `math-app/frontend/lib/screens/home_screen.dart`
- `math-app/frontend/lib/screens/profile_screen.dart`
- `math-app/frontend/lib/services/user_api.dart`
- `math-app/frontend/lib/providers/app_providers.dart`

## Grade-Based Subject Unlocking

The home screen subject grid in `home_screen.dart` defines a `gradeMin` for each tile:

- Grade 1: numbers, geometry, measurement, logic, vietnamese, english
- Grade 2+: algebra
- Grade 3+: trigonometry
- Grade 4+: statistics

Subjects with `gradeMin > userGrade` are hidden entirely.

## Changing Grade

- Profile screen shows chips for grades 1–12.
- Tapping a different grade calls `POST /api/users/grade`.
- On success, `userProvider` is updated in place and related providers are invalidated:
  - `subjectsProvider(grade)`
  - `languageSubjectsProvider(grade)`
  - `rawProgressProvider`
- The user is sent back to `/home` so the new grid loads.

## Backend Impact

- `content-service` and `language-service` filter lessons by grade on most endpoints.
- `user-service` stores `grade` on the user record.
