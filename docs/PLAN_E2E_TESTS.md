# E2E Test Plan — All Screens & Features

## Context

Flutter web uses **CanvasKit** rendering — no semantic HTML, so DOM-based
selectors (button, input, etc.) don't work. Existing E2E suite (8 spec files,
~610 lines) is mostly **API-level** with `request.post/get` and a few
`page.goto()` URL assertions. No real UI interaction tests exist.

**Goal**: Cover all 14 screens + cross-cutting features with deterministic,
non-flaky E2E tests that can run in CI.

**Strategy** (chosen by trade-offs):

| Concern | Approach |
|---|---|
| Auth (skip Google OAuth flow) | Inject guest JWT via `localStorage` |
| Click Flutter widgets | Enable Flutter's **accessibility tree** in build + use ARIA snapshot via Playwright `snapshot()` |
| Visual regression | Coordinate-based screenshots compared to baseline |
| API mocking | `page.route()` to intercept & stub |
| State isolation | Clean `localStorage` / `IndexedDB` between tests via `storageState: undefined` + `addInitScript` |
| Speed | API tests stay as they are; UI tests grouped by screen |

---

## Phase 0 — Foundation & Infrastructure

**Files**:
- `e2e/utils/auth.ts` — `loginAsGuest(page)` injects guest JWT into localStorage
- `e2e/utils/api.ts` — typed wrappers for backend endpoints + helpers
- `e2e/utils/locators.ts` — `byText`, `byRole`, `byKey` for Flutter accessibility
- `e2e/utils/snapshots.ts` — `expectScreen(page, name)` for visual diff
- `e2e/utils/wait.ts` — `waitForFlutterReady(page)` waits for `flt-glass-pane`
- `e2e/fixtures/jwt.ts` — pre-mint guest token, premium token
- `e2e/playwright.config.ts` — add `webServer` for local stack, add `mobile` project

**Flutter build flag** — add to `Dockerfile`:
```
flutter build web --dart-define=ENABLE_ACCESSIBILITY=true ...
```
(also locally: `flutter run -d chrome --dart-define=ENABLE_ACCESSIBILITY=true`)

**Helper pattern** (auth.ts):
```ts
export async function loginAsGuest(page: Page): Promise<void> {
  const res = await page.request.post('/api/auth/guest', { data: {} });
  const { access_token } = (await res.json()).data;
  await page.addInitScript((token) => {
    localStorage.setItem('auth', JSON.stringify({ token, token_type: 'guest' }));
  }, access_token);
  await page.goto('/');
}
```

**Verify**: helper unit-tests in `e2e/utils/*.spec.ts` (no browser needed).

---

## Phase 1 — Auth Flow (3 screens, 12 tests)

**File**: `e2e/tests/auth_flow.spec.ts`

### `LoginScreen`
1. renders title + mascot
2. Google Sign-In button visible
3. Guest button visible
4. Click Guest → navigates to `/welcome` after assessment or `/home`
5. Locale toggle switches vi ↔ en text
6. Facebook fanpage icon (if visible) opens new tab
7. localStorage has `token` + `token_type=google|guest` after login
8. Token persists across reload

### `AuthService` — silent refresh
9. Expiring JWT triggers `/auth/guest` re-issue on next API call
10. 401 from API → interceptor retries once with new token
11. Concurrent calls share single refresh (only 1 network request)

### Logout
12. Profile → Logout clears token + redirects to `/login`

**Tools**: `loginAsGuest`, `loginAsPremium`, `logout`, route assertions.

---

## Phase 2 — Onboarding (2 screens, 8 tests)

**File**: `e2e/tests/onboarding.spec.ts`

### `WelcomeScreen`
1. 4 persona cards visible (Achiever, Struggler, Gamer, Silent)
2. Selecting persona highlights it
3. Start button enabled only after persona selected
4. Locale toggle updates persona names

### `AssessmentScreen`
5. First question renders with options
6. Selecting answer advances to next
7. After N questions → `/home`
8. Skip / back navigation works

---

## Phase 3 — Home + Grade Switching (1 screen, 10 tests)

**File**: `e2e/tests/home.spec.ts`

### `HomeScreen` (authenticated)
1. Grade selector shows 3 pills (Lớp 1/2/3)
2. Active grade pill has checkmark + animation class
3. Tap Lớp 2 → optimistic UI updates immediately
4. POST `/api/users/grade` fires with grade=2
5. Subject grid swaps to grade-2 subjects
6. Each subject card shows lesson count + grade badge
7. Tap subject card → `/subject/:id`

### Facebook contact
8. Top bar shows "Liên hệ" / "Contact" button
9. Click opens Facebook fanpage in new tab
10. Mobile header variant works

---

## Phase 4 — Subject & Lesson (3 screens, 14 tests)

**File**: `e2e/tests/lesson_flow_ui.spec.ts`

### `SubjectScreen`
1. Lists lessons for sub-subject
2. First lesson unlocked
3. Subsequent lessons locked until prior completed
4. Lock icon visible
5. Difficulty badge (1/2/3) shown
6. Tap lesson → navigates to `/lesson/:id`

### `LessonScreen`
7. Exercise renders with question + options
8. Selecting correct answer → next exercise
9. Selecting wrong → retry prompt
10. Completing all exercises → `/celebration`
11. ClockFace widget renders for time exercises
12. Hint button calls `/api/questions/hint`

### `CelebrationScreen`
13. Stars display (1/2/3)
14. "Next" button → next lesson or back to subject

---

## Phase 5 — Profile & Parent (4 screens, 12 tests)

**File**: `e2e/tests/profile_parent.spec.ts`

### `ProfileScreen`
1. Avatar + name + email from `/auth/me`
2. Settings menu shows tier (free/premium)
3. Logout button in menu
4. Tap Logout → `/login` + storage cleared

### `PinGateScreen`
5. 4-digit PIN input accepts digits
6. Wrong PIN shows error
7. Correct PIN → `/parent-dashboard/main`
8. Back button works

### `ParentDashboardScreen`
9. Shows lesson count, streak, accuracy
10. Charts render (canvas present)
11. Date range selector works

### `AchievementScreen` + `LeaderboardScreen`
12. Badges / rankings render with mock data

---

## Phase 6 — Cross-Cutting Features (1 file, 8 tests)

**File**: `e2e/tests/features.spec.ts`

### Bilingual
1. Locale toggle on home switches all visible text
2. Persists in localStorage across reload

### TTS
3. TTS toggle persists across reload
4. Disabled → no `speechSynthesis` calls

### Free tier daily limit
5. JWT with `tier=free` + counter > 50 → lesson screen shows "Daily limit reached"
6. Premium JWT → no limit message

### Premium gating
7. Premium lesson shows lock for free user
8. Free lesson accessible for both tiers

### Connectivity
9. Offline → `ConnectivityService` shows banner
10. Back online → banner disappears, queue drains

---

## Phase 7 — Visual Regression (1 file, 14 tests)

**File**: `e2e/tests/visual.spec.ts`

For each of the 14 screens:
- Mobile (375×812) screenshot
- Desktop (1280×720) screenshot
- Compare against `e2e/fixtures/screenshots/<screen>_<viewport>.png` baseline
- Threshold: 0.1% pixel diff (Flutter renders deterministically)

**Generate baselines**: `npm run test:visual -- --update-snapshots`

---

## File Layout (final)

```
e2e/
├── playwright.config.ts
├── utils/
│   ├── auth.ts            # loginAsGuest, loginAsPremium, logout
│   ├── api.ts             # typed API helpers
│   ├── locators.ts        # byText, byRole, byKey (Flutter a11y)
│   ├── snapshots.ts       # visual diff helpers
│   ├── wait.ts            # waitForFlutterReady
│   └── *.spec.ts          # unit tests for utils
├── fixtures/
│   ├── jwt.ts             # pre-minted tokens
│   └── screenshots/       # visual baselines
└── tests/
    ├── smoke.spec.ts             # KEEP, exists
    ├── auth.spec.ts              # KEEP API + extend
    ├── auth_flow.spec.ts         # NEW Phase 1
    ├── onboarding.spec.ts        # KEEP + extend
    ├── home.spec.ts              # NEW Phase 3
    ├── lesson_flow.spec.ts       # KEEP API + split UI to lesson_flow_ui.spec.ts
    ├── navigation.spec.ts        # KEEP + extend
    ├── progress.spec.ts          # KEEP + extend
    ├── grade_levels.spec.ts      # KEEP
    ├── profile_parent.spec.ts    # NEW Phase 5
    ├── features.spec.ts          # NEW Phase 6
    ├── visual.spec.ts            # NEW Phase 7
    └── api.spec.ts               # KEEP, exists
```

---

## Execution Order

1. **Phase 0** (foundation utils + a11y flag) — 1 PR, gates everything else
2. **Phase 1** (auth_flow) — smoke-test the helper pattern works
3. **Phase 2** (onboarding) — small, fast feedback
4. **Phase 3** (home + grade) — main screen
5. **Phase 4** (lesson flow) — biggest, do after UI patterns solidify
6. **Phase 5** (profile + parent) — isolated, no cross-screen dependencies
7. **Phase 6** (features) — cross-cutting, do last for full coverage
8. **Phase 7** (visual) — generates baselines after UI stabilizes

Each phase = 1 PR. **Stop and verify** at the end of each before continuing.

---

## Acceptance Criteria

- **Coverage**: every route from `app_router.dart` exercised at least once
- **Features**: optimistic grade, silent refresh, locale, TTS, daily limit all tested
- **Stability**: 0 flakes over 10 consecutive CI runs
- **Speed**: full suite < 10 min in CI (parallelize where possible)
- **Determinism**: no time-dependent assertions; visual diffs use ≥0.1% threshold

---

## Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Flutter accessibility tree not stable | Add `Semantics(label: ...)` to key widgets (login button, persona card, etc.) as part of Phase 0 |
| Visual regression too flaky | Phase 7 is last; tolerate up to 0.5% diff for first baseline |
| Google OAuth in CI | Use guest login path; mock GoogleSignIn via `page.route()` if needed |
| Hive localStorage collisions | Clear `auth` + `offline_cache` + `pending_sync` + `settings` boxes in `addInitScript` per test |
| Premium features behind paywall | Use `--dart-define=DEFAULT_TIER=premium` build OR mint a premium JWT for test |

---

## Test Count Estimate

| Phase | Tests | New Files |
|---|---|---|
| 0 | 6 | 6 utils + 1 config |
| 1 | 12 | 1 spec |
| 2 | 8 | 1 spec (extend) |
| 3 | 10 | 1 spec |
| 4 | 14 | 1 spec |
| 5 | 12 | 1 spec |
| 6 | 8 | 1 spec |
| 7 | 14 | 1 spec + 28 baselines |
| **Total** | **~84** | **9 new specs + 6 utils** |
