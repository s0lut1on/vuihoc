# Profile & Settings

The profile screen lets children (or parents) see the child's stats, manage preferences, change grade, and log out.

## Files

- `math-app/frontend/lib/screens/profile_screen.dart`
- `math-app/frontend/lib/services/local_storage_service.dart`
- `math-app/frontend/lib/services/auth_service.dart`
- `math-app/frontend/lib/services/user_api.dart`
- `math-app/frontend/lib/providers/app_providers.dart`

## Profile Header

- Avatar: Google profile picture if available; otherwise the frog mascot.
- Name and email/guest label.

## Stats Cards

- Lessons completed.
- Total stars.
- Streak days.

## Settings Tiles

| Setting | Control | Persistence |
|---|---|---|
| TTS | Switch | Hive (`ttsEnabled`) |
| Daily reminder | Switch | Backend `/notifications/preferences` |
| Sound effects | Switch | Hive (`soundMuted`) |
| Grade | Grade chips 1–12 | Backend `POST /api/users/grade` |

## Grade Change

- Calls `UserApi.updateGrade(grade)`.
- Updates `userProvider` in place.
- Invalidates grade-dependent providers.
- Navigates back to `/home`.

## Logout

- Calls `AuthService().signOut()`.
- Invalidates `currentUserProvider`, `userProvider`, and `userIdProvider`.
- Routes to `/login`.
