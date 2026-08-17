# Admin Dashboard

A simple admin screen for internal content and user management. It is protected by the normal auth middleware plus an admin role check on backend admin routes.

## Files

- `math-app/frontend/lib/screens/admin_dashboard_screen.dart`
- `math-app/backend/content/src/main.rs`
- `math-app/backend/shared/src/lib.rs` (admin middleware)

## Frontend

- Route `/admin` renders `AdminDashboardScreen`.
- Provides forms to create/edit subjects, lessons, and exercises.
- Calls `content-service` admin endpoints.

## Backend Admin Routes

All admin routes apply `shared::auth_middleware` and `shared::require_admin`:

- `POST /api/content/admin/subjects`
- `PUT /api/content/admin/subjects/:id`
- `POST /api/content/admin/lessons`
- `PUT /api/content/admin/lessons/:id`
- `DELETE /api/content/admin/lessons/:id`
- `POST /api/content/admin/exercises`
- `PUT /api/content/admin/exercises/:id`

## Authorization

- Only users with the admin role in the database can mutate content.
