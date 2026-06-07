# Incoming Features — Implementation Plans

Status: **Backlog** | Priority: TBD per sprint

This folder contains scoped implementation plans for new features. Each plan includes scope, affected files, effort estimate, and MVP checklist.

| # | Feature | Effort | Backend | Frontend | Value |
|---|---------|--------|---------|----------|-------|
| 1 | Spaced Repetition + Weak Spot Drill | 2-3 days | Medium | Low | High |
| 2 | Daily Streak + Achievements | 1-2 days | Low | Medium | High |
| 3 | Text-to-Speech for Language Exercises | 0.5 days | None | Medium | Medium |
| 4 | Offline Exercise Cache | 2-3 days | Low | Medium | Medium |
| 5 | Parent Report Notifications | 2-3 days | Medium | Low | Medium |
| 6 | Peer / Sibling Leaderboard (Anonymous) | 2-3 days | Medium | Medium | Medium |
| 7 | AI-Generated Hints (Controlled) | 1-2 days | Medium | Medium | Medium |
| 8 | Subject-Specific Unlock Animations | 1-2 days | None | High | Low |

## How to use

1. Move a plan from `incoming/` to `docs/` when it gets sprint commitment.
2. Update `math-app/frontend/lib/main.dart` route guards or `math-app/backend/*/src/main.rs` startup configs as noted in each plan.
3. After implementation, archive the plan to `docs/archive/`.

## Dependencies

- Most plans depend on the `progress-service` running the new `detailed` endpoint (`/progress/detailed/{user_id}`) — confirmed live in production.
- Plan 7 (AI Hints) requires the `ANTHROPIC_API_KEY` env var to be set (currently blank on production; must be filled before enable).
