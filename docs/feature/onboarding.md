# Onboarding

Onboarding happens after authentication and before the home screen. It captures the child's **persona** and **grade** so the app can adapt tone, encouragement, and available subjects.

## Files

- `math-app/frontend/lib/screens/welcome_screen.dart`
- `math-app/frontend/lib/screens/assessment_screen.dart`
- `math-app/frontend/lib/models/persona_model.dart`
- `math-app/frontend/lib/services/user_api.dart`
- `math-app/frontend/lib/services/local_storage_service.dart`

## Persona Selection

Four personas are available:

| Persona | Vietnamese label | Tone |
|---|---|---|
| `achiever` | Học giỏi | Praise-driven, goal-oriented |
| `gamer` | Chơi game | Rewards, points, unlocks |
| `struggler` | Cần động viên | Gentle encouragement, no pressure |
| `silent` | Nhút nhát | Quiet, calm, minimal distraction |

The selected persona is sent to `POST /api/users` and persisted with the user record.

## Grade Selection

- Grades 1–12 are shown as chips.
- Default grade is 1.
- Grade controls which subjects are unlocked on the home screen and which lessons are loaded.

## Optional Assessment

- `/assessment` asks 4 questions about counting ability, letter/number knowledge, learning speed, and preferred motivation.
- Answers are stored locally only (`saveOnboardingComplete`).
- The assessment route is public and can be skipped.

## Completion

- After persona + grade are chosen, `UserApi.createUser()` creates the profile.
- `LocalStorageService.saveOnboardingComplete()` marks onboarding done.
- The user is routed to `/home`.
