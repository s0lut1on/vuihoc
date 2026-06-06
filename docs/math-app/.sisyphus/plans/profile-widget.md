# Profile Widget Plan

## Goal
Replace the `Bắt đầu` (Start) button in the `WelcomeScreen` desktop navigation bar (top-right) with a user avatar and dropdown menu.

## Context

### Current State
- `WelcomeScreen` (`frontend/lib/screens/welcome_screen.dart`) has two instances of a "Bắt đầu" button:
  1. **Desktop nav bar** (`_buildDesktopNav`, line 242-257): `ElevatedButton` in top-right — this is what we replace with the profile widget.
  2. **Main CTA** (line 117-131): Large `ElevatedButton` below persona selection — this stays (it's the flow's primary action).
- Previous "commit change" cleaned up the duplicate desktop nav "Bắt đầu" by removing it during the LoginScreen refactor, but it appears to have been re-introduced or was actually the remaining one from the mobile nav.
- Auth is handled via `AuthService` with JWT tokens stored in Hive. Backend `auth` service issues JWTs with user claims.
- `UserNotifier` exists in `app_providers.dart` but only wraps backend `createUser`/`getUser` calls. No reactive auth state stream exists.
- `userProvider` returns `AsyncValue<User?>` but is not automatically populated on app start from the stored JWT.

### What We Build
A `ProfileWidget` (avatar + name + dropdown) in the desktop nav that:
1. Shows the user's avatar (Google profile picture, or a default emoji) and name when signed in.
2. Shows a generic "Guest" avatar when logged in as guest.
3. Opens a dropdown on tap with: Profile, Settings, Logout.
4. Logout clears the auth token, resets user state, and navigates to `/login`.
5. Works on both desktop (`_buildDesktopNav`) and mobile (top app bar if needed).

---

## Files to Modify

### Backend

| File | Change |
|------|--------|
| `backend/auth/src/models.rs` | Add `MeResponse` struct: `{ id, email, name, picture, given_name }`. Add to OpenAPI schema list. |
| `backend/auth/src/handlers.rs` | Add `get_current_user` handler: read `Authorization` Bearer token → decode JWT → return `MeResponse`. Reuse existing `Claims` decoding. |
| `backend/auth/src/main.rs` | Wire `GET /api/auth/me` route. |

### Frontend

| File | Change |
|------|--------|
| `frontend/lib/services/auth_service.dart` | Add `getCurrentUser()` → `GET /auth/me` with `ApiService` token. Add `authStateChanges` `StreamController<bool>` to notify UI of sign-in/out. Emit on `signInWithGoogle`, `signInAsGuest`, `signOut`. |
| `frontend/lib/providers/app_providers.dart` | Add `authUserProvider` as `StreamProvider<bool>` driven by `AuthService.authStateChanges`. Add `currentUserProvider` as `FutureProvider` that calls `AuthService.getCurrentUser()` and caches result. Update `UserNotifier` to set `userIdProvider` on `loadUser`. |
| `frontend/lib/widgets/profile_widget.dart` | **New file** — `ConsumerWidget` that: (a) watches `currentUserProvider`, (b) shows `CircleAvatar` with user's `picture` or default emoji, (c) tap opens dropdown (`PopupMenuButton`) with Profile, Settings, Logout, (d) logout calls `AuthService.signOut()` + `context.go('/login')`. |
| `frontend/lib/screens/profile_screen.dart` | **New file** — Full profile page: large avatar, name, email, persona badge, stats (lessons, stars, streak), edit name button (optional). |
| `frontend/lib/screens/welcome_screen.dart` | `_buildDesktopNav()`: remove `ElevatedButton("Bắt đầu")` (line 242-257), replace with `ProfileWidget()`. Keep the main CTA button below persona selection. Add `const SizedBox(width: 16)` between `LanguageSwitcher` and `ProfileWidget`. |
| `frontend/lib/core/app_router.dart` | Add `GoRoute(path: '/profile', builder: ProfileScreen())`. |
| `frontend/lib/l10n/app_en.arb` | Add: `profile`, `settings`, `logout`, `profileTitle`, `guestUser`, `anonymous`. |
| `frontend/lib/l10n/app_vi.arb` | Add: `profile`, `settings`, `logout`, `profileTitle`, `guestUser`, `anonymous`. |

### Tests

| File | Coverage |
|------|----------|
| `frontend/test/widgets/profile_widget_test.dart` | **New** — (a) renders avatar, (b) tap opens dropdown, (c) logout tap calls `AuthService.signOut()`, (d) shows guest state when no user. |
| `frontend/test/services/auth_service_test.dart` | Update — add `getCurrentUser` success/failure tests. |
| `frontend/test/screens/profile_screen_test.dart` | **New** — renders profile page with user data. |

### Config / Docs

| File | Change |
|------|--------|
| `CHANGELOG.md` | Add entry under "Profile Widget" section. |

---

## Detailed Design

### 1. Backend: `GET /api/auth/me`

**Request**
```
GET /api/auth/me
Authorization: Bearer <jwt>
```

**Response (200)**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@gmail.com",
    "name": "Nam",
    "picture": "https://lh3.googleusercontent.com/...",
    "given_name": "Nam"
  }
}
```

**Implementation**
- In `auth/src/handlers.rs`, decode JWT using the existing `JWT_SECRET` env var.
- If token invalid / missing → `401 Unauthorized`.
- If valid → construct `MeResponse` from `Claims` (sub = id, email, name, picture).
- Guest users also have JWTs (sub = UUID, no email/picture). Return with empty `email` and `picture`.

### 2. Frontend: `AuthService.getCurrentUser()`

```dart
Future<Map<String, dynamic>?> getCurrentUser() async {
  try {
    final response = await ApiService().get('/auth/me');
    return response['data'] as Map<String, dynamic>?;
  } catch (e) {
    return null;
  }
}
```

**Auth state stream**
- Add `StreamController<bool> _authState = StreamController<bool>.broadcast();`
- `Stream<bool> get authStateChanges => _authState.stream;`
- Emit `_authState.add(true)` on successful `signInWithGoogle` / `signInAsGuest`.
- Emit `_authState.add(false)` on `signOut`.

### 3. Frontend: `ProfileWidget`

**UI**
```
[Avatar] [Name] [▼]
```
- Avatar: `CircleAvatar` with `NetworkImage(picture)` if picture not empty; else `Text('🐸')` or first letter of name.
- Text: user's `name` or `"Khách"` (Guest) if guest.
- Dropdown (`PopupMenuButton`):
  - Hồ sơ → `context.go('/profile')`
  - Cài đặt → `context.go('/settings')` (or show snackbar "Coming soon")
  - Đăng xuất → `AuthService().signOut(); context.go('/login');`

**Placement in `WelcomeScreen._buildDesktopNav()`**
```dart
Row(
  children: [
    const LanguageSwitcher(),
    const SizedBox(width: 16),
    const ProfileWidget(),  // replaces the old ElevatedButton
  ],
)
```

### 4. Frontend: `ProfileScreen`

- App bar with back button → `context.go('/home')`.
- Center column:
  - Large `CircleAvatar` (80px) with picture or default.
  - Name text (headlineSmall).
  - Email text (bodyMedium, grey).
  - Persona badge chip (colored).
  - Stats row: Lessons, Stars, Streak (icon + number).
  - Optional: Edit name button → `TextField` + Save.

### 5. Data Flow

```
App Start
  → AuthService.silentSignIn() → if token exists
      → ApiService.setToken(token)
      → _authState.add(true)
      → UI refreshes via authUserProvider

WelcomeScreen Desktop Nav
  → ProfileWidget
      → watches currentUserProvider
      → if user loaded: shows avatar + name + dropdown
      → if no user: shows generic guest avatar + "Khách"

Logout Tap
  → AuthService.signOut()
      → clears token, Hive, _authState.add(false)
      → context.go('/login')
```

---

## Acceptance Criteria

- [ ] Desktop nav shows `ProfileWidget` (avatar + name) instead of `Bắt đầu` button.
- [ ] Main CTA button below persona selection still says `Bắt đầu học!` and is unaffected.
- [ ] Profile dropdown has: Profile, Settings, Logout.
- [ ] Logout clears auth state and redirects to `/login`.
- [ ] `make deploy` passes **22/22 E2E tests**.
- [ ] `flutter analyze` clean.
- [ ] `CHANGELOG.md` updated with profile widget entry.
- [ ] `.env` / secrets untouched.

---

## Dependencies

- No new pub packages needed (already using `google_sign_in`, `flutter_riverpod`, `go_router`).
- Backend: no new crates (existing `axum`, `jsonwebtoken`, `serde`).

## Open Questions

1. **Guest avatar**: Should we generate a colorful default avatar for guests (e.g., first letter + random color), or just use the frog emoji 🐸?
Answer: Generate colorful default avatar for guests
2. **Settings page**: Do we implement a real settings page now, or just show "Coming soon" in the dropdown?
Answer: Just show "Coming soon"
3. **Mobile placement**: Should `ProfileWidget` also appear in mobile layout (e.g., top-right of `SafeArea`), or only on desktop?
Answer: First is only for desktop

## Implementation Order

1. Backend `GET /api/auth/me`
2. `AuthService.getCurrentUser()` + `authStateChanges`
3. `ProfileWidget`
4. `ProfileScreen`
5. Wire into `WelcomeScreen._buildDesktopNav()`
6. Add route in `app_router.dart`
7. Add i18n strings
8. Write tests
9. Run `make deploy`
10. Update `CHANGELOG.md`

---

*Plan created: 2026-05-05*
*Status: Pending approval — do not implement until user says "go"*
