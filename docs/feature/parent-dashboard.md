# Parent Dashboard

A PIN-gated dashboard for parents to view learning progress, manage settings, and disable overstimulating animations.

## Files

- `math-app/frontend/lib/screens/pin_gate_screen.dart`
- `math-app/frontend/lib/screens/parent_dashboard_screen.dart`
- `math-app/frontend/lib/services/local_storage_service.dart`
- `math-app/frontend/lib/services/language_api.dart`

## PIN Gate

- Route `/parent-dashboard` renders `PinGateScreen`.
- Correct PIN is `1234` (hard-coded in the Flutter app).
- Wrong PIN triggers a shake animation and a snackbar.
- Success routes to `/parent-dashboard/main`.

## Dashboard Content

- Header with family mascot.
- Stats cards: lessons learned, stars earned, study streak.
- Child progress: per-subject and per-sub-subject completion bars with percentages.
- Settings:
  - Language (display only).
  - Study time (display only).
  - Notifications toggle.
  - Unlock-celebration animation toggle.
  - Parent email + weekly report frequency.
  - Logout.

## Progress Source

- `LanguageApi.getDetailedProgress(userId)` returns the full subject/sub-subject tree with completion percentages.
