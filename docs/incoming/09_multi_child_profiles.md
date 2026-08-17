# Plan: Multi-Child Profiles

## Problem
One account = one kid. Parents with multiple children (common in Vietnam) must create separate accounts or share progress. This limits household adoption — parents won't create 3 accounts for 3 kids.

## Goal
Allow one parent account to manage multiple child profiles. Each child has:
- Independent progress, persona, grade, streak
- Separate lesson history and weak-spot tracking
- Child switcher on the home screen

## Scope

### MVP — Backend (3-4 days)

**User model refactor** (`user-service`):
- Add `parent_id` column to `users` table (nullable UUID, self-referencing FK)
- `parent_id = NULL` means this IS the parent account
- `parent_id = <uuid>` means this IS a child profile owned by that parent
- Migrate existing `users` — set parent_id = their own id for current "parent+child" accounts that were created during auth

**New endpoints** (`user-service`):
| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/users/children` | Bearer | List all child profiles under this parent |
| POST | `/api/users/children` | Bearer | Create a new child profile (name, persona, grade) |
| DELETE | `/api/users/children/:child_id` | Bearer | Remove a child profile |
| PUT | `/api/users/default-child` | Bearer | Set which child is active (stored in session) |

**Auth service changes**:
- On Google Sign-In / guest login: create a PARENT account + auto-create 1 child profile ("Bé", achiever, grade 1)
- `POST /api/auth/register` — same behavior

**Content + Progress scoped to child**:
- All `/api/content/*`, `/api/progress/*`, `/api/questions/*` endpoints already use `user_id` from JWT claims
- The active child's UUID is the JWT `sub` claim — no backend changes needed for scoping
- Frontend requests a new JWT when switching children (child id becomes the new `sub`)

### MVP — Frontend (2-3 days)

**Profile switcher** in `KidNavBar`:
- Add a dropdown/avatar row showing current child name + avatar
- Tap opens child picker modal with all children + "Add child" button
- Selecting a child:
  1. Calls `/api/users/default-child` to persist preference
  2. Gets a new JWT with the child's UUID as `sub`
  3. Refreshes all providers (invalidate key providers)
  4. Redirects to `/home`

**Add child flow**:
- Modal with: name (text field), persona (4-option picker), grade (1-12 chip selector)
- Calls `POST /api/users/children`

**Child avatar**:
- Use emoji avatar per child (auto-assigned or picked)
- Show in nav bar + profile screen

**Profile screen** (`profile_screen.dart`):
- Add "Manage children" section above logout
- Show list of children with edit/delete
- Active child highlighted

### V2
- Child-specific unlock animations per avatar
- Separate achievement progress per child
- Parent dashboard shows ALL children side-by-side

## Affected Files

### Backend
- `math-app/backend/user/src/models.rs` — add parent_id, default-child endpoints
- `math-app/backend/user/src/handlers.rs` — children CRUD handlers
- `math-app/backend/user/src/main.rs` — new routes
- `math-app/backend/user/migrations/` — add `parent_id` to users, default_child table
- `math-app/backend/auth/src/handlers.rs` — create parent+child on signup

### Frontend
- `math-app/frontend/lib/widgets/kid_nav_bar.dart` — child switcher dropdown
- `math-app/frontend/lib/screens/profile_screen.dart` — "Manage children"
- `math-app/frontend/lib/screens/child_switcher_screen.dart` — new, modal picker
- `math-app/frontend/lib/screens/add_child_screen.dart` — new
- `math-app/frontend/lib/services/user_api.dart` — add children API methods
- `math-app/frontend/lib/providers/app_providers.dart` — add `activeChildProvider`, invalidate on switch
- `math-app/frontend/lib/services/auth_service.dart` — JWT re-issue on child switch

## Effort Estimate
- **Backend**: 3-4 days (model refactor, new endpoints, auth integration)
- **Frontend**: 2-3 days (switcher UI, add child flow, provider wiring)
- **Testing**: 1 day
- **Total**: ~7 days

## Risks
- JWT re-issue on every child switch adds latency. Mitigation: cache child tokens, refresh proactively.
- Existing users have "merged" parent+child identity — migration script needed to split.
- Lessons-in-progress lost when switching child. Show confirmation dialog.

## Success Criteria
- [ ] Parent can add 2+ children from profile screen
- [ ] Home screen shows current child name in nav bar
- [ ] Tapping child name opens picker with all children listed
- [ ] Switching child loads that child's progress (lessons, streaks, achievements)
- [ ] Each child has independent lesson history
- [ ] Parent dashboard shows all children's data aggregated
