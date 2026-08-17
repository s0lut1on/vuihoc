# Notifications

The app can register for Firebase Cloud Messaging (FCM) push notifications and manage daily reminder preferences.

## Files

- `math-app/frontend/lib/services/notification_service.dart`
- `math-app/frontend/lib/screens/profile_screen.dart`
- `math-app/backend/notification/src/`

## FCM Registration

- `NotificationService.initialize()` runs after login.
- Skips if Firebase is not initialized (e.g., web without config).
- On mobile, requests notification permission first.
- Fetches the FCM token and posts it to `POST /api/notifications/subscribe`.
- Listens to `onTokenRefresh` and re-subscribes the new token.

## Preferences

- `GET /api/notifications/preferences`
- `PUT /api/notifications/preferences` with `daily_reminder_enabled` and optional `reminder_hour`.
- Profile screen toggle updates `dailyReminderEnabledProvider` and calls the backend.

## Unsubscribe

- `NotificationService.unsubscribe()` deletes the token and calls `POST /api/notifications/unsubscribe`.
