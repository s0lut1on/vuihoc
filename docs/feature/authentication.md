# Authentication

Users sign in via **Google Sign-In** or **Guest login**. Both flows return a JWT access token from the backend, which the Flutter app stores in Hive and sends on all protected API requests.

## Files

- `math-app/frontend/lib/services/auth_service.dart`
- `math-app/frontend/lib/services/api_service.dart`
- `math-app/frontend/lib/main.dart`
- `math-app/backend/auth/src/handlers.rs`
- `math-app/backend/auth/src/models.rs`

## Google Sign-In

- Uses the `google_sign_in` plugin.
- On web/desktop, the OAuth `clientId` is read from the `GOOGLE_CLIENT_ID` Dart define.
- On Android, the plugin reads credentials from `google-services.json`; the web client ID is passed as `serverClientId` so the plugin returns an `idToken`.
- Sends either `id_token` (preferred) or `access_token` to `POST /api/auth/google`.
- Backend verifies the token and returns a JWT.

## Guest Login

- Calls `POST /api/auth/guest` with no payload.
- Backend creates a guest identity and returns a JWT.
- Guest accounts are tracked separately in `token_type = 'guest'`.

## Token Lifecycle

- Token is stored in the `auth` Hive box (`token`) and mirrored into `ApiService` and `AuthService.tokenNotifier`.
- On app startup, the token is loaded before `runApp` so the router can route to `/home` immediately.
- `silentSignIn()` calls `GET /api/auth/me` in the background; if it fails, the user is signed out and redirected to `/login`.
- Proactive refresh: `AuthService._scheduleProactiveRefresh()` decodes the JWT `exp` claim and refreshes the token 5 minutes before expiry.
- Reactive refresh: `ApiService` 401 interceptor calls `refreshTokenSilently()` and retries the request once.
- Concurrent refresh calls coalesce into a single in-flight future.

## Logout

- Signs out of Google (if applicable).
- Clears the token from memory and Hive.
- Resets `tokenNotifier`, which triggers the router redirect to `/login`.

## Routes

- `/login` — public.
- `/welcome` — public (post-auth onboarding).
- All other routes require a non-empty token.
