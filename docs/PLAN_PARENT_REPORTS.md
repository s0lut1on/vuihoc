# Plan: Parent Dashboard Reports — Daily + Weekly Email

> **Status:** Draft — not yet started
> **Created:** 2026-09-11
> **Owner:** Orchestrator
> **Depends on:** notification service, progress service, SendGrid account

---

## Problem

The parent dashboard exists in-app but the email report pipeline is broken at 3 points:

1. **No scheduler** — `POST /api/notifications/send-report` endpoint exists but nothing triggers it
2. **No SendGrid key** — `SENDGRID_API_KEY` env var not set on VPS
3. **Frontend doesn't sync to backend** — Parent email saved to local Hive only, never reaches `notification_preferences` table

Additionally:
- No daily report exists (only weekly)
- Email content is generic plain text (no real progress data)
- Streak on dashboard is hardcoded `"5"`
- No premium gating on email reports feature
- No HTML email template

---

## Current State

### What exists

| Component | File | Status |
|-----------|------|--------|
| Parent dashboard UI | `frontend/lib/screens/parent_dashboard_screen.dart` | ✅ Shows stats, progress bars, email prefs UI |
| Email prefs (frontend) | `frontend/lib/services/local_storage_service.dart:97-119` | ✅ Saves to Hive (parentEmail, emailFrequency) |
| Email prefs (backend) | `notification/src/handlers.rs:135-190` | ✅ `GET/PUT /api/notifications/preferences` |
| notification_preferences table | `notification/migrations/001 + 003` | ✅ Has `parent_email`, `email_reports_enabled` columns |
| Weekly report endpoint | `notification/src/handlers.rs:274-336` | ✅ `POST /api/notifications/send-report` — queries prefs, sends via SendGrid |
| email_logs table | `notification/migrations/003_email_logs.sql` | ✅ Logs sent emails |
| Progress data | `progress/src/handlers.rs` | ✅ `/api/progress/{user_id}`, `/api/progress/streak/{user_id}`, `/api/progress/score/{user_id}` |
| Streak data | `progress/src/models.rs:62-67` | ✅ `Streak { current_streak, best_streak, last_activity }` |
| User score data | `progress/src/models.rs:138-147` | ✅ `UserScore { total_score, correct_count, lessons_completed }` |

### What's broken / missing

| Issue | Impact |
|-------|--------|
| No cron/scheduler | Report endpoint never called automatically |
| `SENDGRID_API_KEY` not set | Handler returns "not set, skipping" |
| Frontend saves email locally only | Backend `notification_preferences.parent_email` never populated |
| No daily report | Only weekly exists |
| Email content generic | Plain text "bé đã hoàn thành các bài học" — no stats |
| Streak hardcoded `"5"` | Dashboard shows fake streak |
| No premium gating | Free users can see email prefs UI |
| No HTML template | Plain text only |

---

## Architecture Decision: Email Provider

**SendGrid** — already integrated in `notification/src/handlers.rs:287-310`. Free tier: 100 emails/day. Sufficient for early user base.

**Alternative considered:** Amazon SES (cheaper at scale, $0.10/1k vs SendGrid $0.001/email after free tier). But SendGrid already coded — switching adds no value now. Can switch later if volume justifies.

**Decision:** Keep SendGrid. Set up API key.

---

## Implementation Plan

### Phase 1: Fix Frontend → Backend Sync (1 day)

**Goal:** Parent email + frequency saved to backend, not just local Hive.

#### 1.1 Extend `UpdatePreferencesRequest` model

**File:** `backend/notification/src/models.rs`

Add fields to `UpdatePreferencesRequest`:
```rust
pub struct UpdatePreferencesRequest {
    pub daily_reminder_enabled: Option<bool>,
    pub reminder_hour: Option<i32>,
    pub timezone: Option<String>,
    // NEW:
    pub parent_email: Option<String>,
    pub email_reports_enabled: Option<bool>,
    pub report_frequency: Option<String>,  // "daily" | "weekly" | "never"
}
```

#### 1.2 Update `update_preferences` handler

**File:** `backend/notification/src/handlers.rs:172-190`

Extend the `INSERT ... ON CONFLICT DO UPDATE` to include `parent_email`, `email_reports_enabled`, `report_frequency`.

#### 1.3 Update `NotificationPreferences` model

**File:** `backend/notification/src/models.rs:46-54`

Add fields:
```rust
pub struct NotificationPreferences {
    // ...existing...
    pub parent_email: Option<String>,
    pub email_reports_enabled: bool,
    pub report_frequency: String,  // "daily" | "weekly" | "never"
}
```

#### 1.4 Add migration

**File:** `backend/notification/migrations/004_report_frequency.sql`

```sql
ALTER TABLE notification_preferences
  ADD COLUMN IF NOT EXISTS report_frequency VARCHAR(10) NOT NULL DEFAULT 'never';
```

#### 1.5 Update Flutter parent dashboard to sync to backend

**File:** `frontend/lib/screens/parent_dashboard_screen.dart`

- When parent saves email → also `PUT /api/notifications/preferences` with `{ parent_email, email_reports_enabled, report_frequency }`
- When parent changes frequency → same PUT call
- Keep Hive as cache, but backend is source of truth
- Add `_syncToBackend()` method called after `_saveEmail()` and `_saveFrequency()`

#### 1.6 Add premium gating in Flutter UI

**File:** `frontend/lib/screens/parent_dashboard_screen.dart`

- Check `userTierProvider` — if not premium, show lock icon on email prefs section
- Tapping shows paywall modal or pricing screen
- Free users can see dashboard stats but not enable email reports

**Deliverable:** Parent enters email in app → email reaches backend `notification_preferences` table.

---

### Phase 2: Fix Streak on Dashboard (0.5 day)

**Goal:** Dashboard shows real streak from progress API, not hardcoded `"5"`.

#### 2.1 Add streak provider

**File:** `frontend/lib/providers/app_providers.dart`

```dart
final userStreakProvider = FutureProvider.autoDispose<Streak?>((ref) async {
  final user = ref.watch(userProvider).value;
  if (user == null) return null;
  final api = ApiService();
  final resp = await api.get('/progress/streak/${user.id}');
  return resp != null ? Streak.fromJson(resp['data']) : null;
});
```

#### 2.2 Update dashboard to use real streak

**File:** `frontend/lib/screens/parent_dashboard_screen.dart:248-251`

Replace hardcoded `'5'` with `streak?.current_streak.toString() ?? '0'`.

**Deliverable:** Dashboard streak shows real value from `/api/progress/streak/{userId}`.

---

### Phase 3: Build Report Data Aggregator (1.5 days)

**Goal:** Notification service can fetch real progress data to include in email body.

#### 3.1 Add progress API client to notification service

**File:** `backend/notification/src/handlers.rs` (or new `report_data.rs` module)

Create async function that calls progress service internally:

```rust
pub struct ReportData {
    pub user_id: Uuid,
    pub lessons_completed_week: i32,
    pub lessons_completed_total: i32,
    pub total_stars: i32,
    pub current_streak: i32,
    pub best_streak: i32,
    pub total_score: i32,
    pub correct_count: i32,
    pub subjects: Vec<SubjectProgress>,
}

pub struct SubjectProgress {
    pub name_vi: String,
    pub name_en: String,
    pub completed: i32,
    pub stars: i32,
    pub completion_pct: f64,
}
```

#### 3.2 Implement `fetch_report_data(user_id, period)`

- Call `GET http://progress-service:3000/api/progress/{user_id}` — all progress rows
- Call `GET http://progress-service:3000/api/progress/streak/{user_id}` — streak
- Call `GET http://progress-service:3000/api/progress/score/{user_id}` — score
- Filter progress rows by `updated_at` within period (daily = today, weekly = last 7 days)
- Aggregate: count completed lessons, sum stars, group by subject_id
- Subject names: either join with content DB or embed subject_id mapping (simpler: hardcode map or fetch from content service)

**Note:** Internal service-to-service calls use Docker network (`http://progress-service:3000`), not public Traefik. No auth needed inside Docker network.

#### 3.3 Add `GET /api/notifications/report-data/{user_id}` endpoint

Returns `ReportData` as JSON. Useful for:
- Previewing report content in the app before sending
- Testing data aggregation without sending email

**Deliverable:** `GET /api/notifications/report-data/{user_id}` returns real progress data.

---

### Phase 4: Build HTML Email Template (1 day)

**Goal:** Branded HTML email with real data, not generic plain text.

#### 4.1 Create email template module

**File:** `backend/notification/src/email_template.rs`

Two templates:
- `render_daily_report_vi(data: &ReportData) -> String` — Vietnamese daily
- `render_weekly_report_vi(data: &ReportData) -> String` — Vietnamese weekly
- `render_daily_report_en(data: &ReportData) -> String` — English daily
- `render_weekly_report_en(data: &ReportData) -> String` — English weekly

#### 4.2 Template structure (inline CSS, SendGrid-compatible)

```
┌─────────────────────────────────────┐
│  🐸 HocVui                          │
│  Báo cáo học tập — [Daily/Weekly]   │
├─────────────────────────────────────┤
│                                     │
│  Chào phụ huynh,                    │
│                                     │
│  [Tên bé] đã học:                   │
│                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐           │
│  │ 📚  │ │ ⭐  │ │ 🔥  │           │
│  │  12 │ │  35 │ │  7  │           │
│  │bài  │ │sao  │ │ngày │           │
│  └─────┘ └─────┘ └─────┘           │
│                                     │
│  Tiến độ theo môn:                  │
│  • Toán      ████████░░ 80%        │
│  • Tiếng Việt ████░░░░░░ 40%        │
│  • Tiếng Anh  ██░░░░░░░░ 20%        │
│                                     │
│  Thành tích mới: 🏆 7 ngày liên tục │
│                                     │
│  Xem chi tiết: sekklings.com/app    │
│                                     │
├─────────────────────────────────────┤
│  HocVui — Toán vui cho bé           │
│  contact@sekklings.com              │
└─────────────────────────────────────┘
```

- Inline CSS only (email client compatibility)
- Max width 600px
- HocVui brand colors (`#FF6B9D`, `#FFE0EC`, `#4A5568`)
- mascot emoji 🐸
- CTA button: "Xem chi tiết" → `https://sekklings.com/app`
- Unsubscribe link at bottom

#### 4.3 Update `send_report` handler to use HTML template

**File:** `backend/notification/src/handlers.rs:274-336`

- Fetch `ReportData` via `fetch_report_data(user_id, period)`
- Determine language from user's locale preference
- Render HTML via `email_template.rs`
- SendGrid content: `type: "text/html"` + `type: "text/plain"` (multipart)
- Subject: daily = "Báo cáo học tập hôm nay 📚", weekly = "Báo cáo học tập tuần này của bé 🌟"

**Deliverable:** Email sent with real progress data in branded HTML.

---

### Phase 5: Add Daily Report Endpoint (0.5 day)

**Goal:** Support daily reports in addition to weekly.

#### 5.1 Add `send_daily_report` handler

**File:** `backend/notification/src/handlers.rs`

```rust
pub async fn send_daily_report(State(state): State<AppState>) -> String {
    // Query: WHERE report_frequency = 'daily' AND parent_email IS NOT NULL
    // For each user: fetch_report_data(user_id, Period::Daily)
    // Render daily template, send via SendGrid
}
```

#### 5.2 Update `send_report` to support frequency param

Refactor existing `send_report` into:
- `send_weekly_report()` — queries `report_frequency = 'weekly'`
- `send_daily_report()` — queries `report_frequency = 'daily'`

#### 5.3 Add route

**File:** `backend/notification/src/main.rs`

```rust
.route("/api/notifications/send-daily-report", post(handlers::send_daily_report))
.route("/api/notifications/send-weekly-report", post(handlers::send_weekly_report))
```

Keep `/api/notifications/send-report` as alias to weekly for backward compat.

**Deliverable:** Both daily and weekly report endpoints exist.

---

### Phase 6: Cron Scheduler (0.5 day)

**Goal:** Reports sent automatically on schedule.

#### 6.1 Option A: Docker cron sidecar (recommended)

Add a lightweight cron container to `docker-compose.prod.yml`:

```yaml
notification-cron:
  image: alpine:latest
  depends_on: [notification-service]
  environment:
    - NOTIFICATION_URL=http://notification-service:3000
  command: >
    sh -c "echo '0 20 * * * wget -qO- $$NOTIFICATION_URL/api/notifications/send-daily-report' > /etc/crontabs/root &&
           echo '0 9 * * 0 wget -qO- $$NOTIFICATION_URL/api/notifications/send-weekly-report' > /etc/crontabs/root &&
           crond -f"
  restart: unless-stopped
```

- **Daily:** 20:00 ICT (13:00 UTC) — end of kid's study day
- **Weekly:** Sunday 09:00 ICT (02:00 UTC) — weekend summary for parents

#### 6.2 Option B: VPS host crontab

```bash
# On VPS:
crontab -e
# Daily at 20:00 ICT
0 13 * * * docker exec math-app-notification-service-1 wget -qO- http://localhost:3000/api/notifications/send-daily-report
# Weekly Sunday 09:00 ICT
0 2 * * 0 docker exec math-app-notification-service-1 wget -qO- http://localhost:3000/api/notifications/send-weekly-report
```

**Decision:** Option A (Docker sidecar) — lives in compose file, survives VPS rebuilds, no manual setup.

**Deliverable:** Reports sent automatically without manual intervention.

---

### Phase 7: SendGrid Setup + Deploy (0.5 day)

**Goal:** SendGrid API key configured, end-to-end test.

#### 7.1 Create SendGrid account

- Sign up at sendgrid.com (free tier: 100 emails/day)
- Verify sender domain `sekklings.com` (add DNS records in Cloudflare)
- Generate API key with "Mail Send" permission
- Store key securely

#### 7.2 Add env var to VPS

**File:** VPS `/root/math-app/math-app/.env`

```bash
SENDGRID_API_KEY=SG.xxxxxxxx
```

Add to `docker-compose.prod.yml` notification-service env section:
```yaml
- SENDGRID_API_KEY=${SENDGRID_API_KEY}
```

#### 7.3 End-to-end test

1. In app: parent enters email, selects "weekly"
2. Verify backend `notification_preferences` row has email + frequency
3. `curl -X POST https://sekklings.com/api/notifications/send-weekly-report`
4. Verify email received with real data
5. Check `email_logs` table has log entry

**Deliverable:** Real email sent to parent with actual progress data.

---

### Phase 8: Report Preview in App (0.5 day)

**Goal:** Parents can preview what the email report looks like before enabling.

#### 8.1 Add "Xem mẫu" (Preview) button in email prefs section

**File:** `frontend/lib/screens/parent_dashboard_screen.dart`

- Button calls `GET /api/notifications/report-data/{user_id}`
- Shows modal with rendered HTML (using `flutter_html` package or simple layout)
- Helps parents understand value before enabling

#### 8.2 Add report history screen

- Shows list of sent reports from `email_logs` table
- `GET /api/notifications/email-logs/{user_id}` — new endpoint
- Parents can see what was sent and when

**Deliverable:** Parents can preview report content in-app.

---

## File Change Summary

| File | Phase | Change |
|------|-------|--------|
| `backend/notification/src/models.rs` | 1 | Add `parent_email`, `email_reports_enabled`, `report_frequency` to `UpdatePreferencesRequest` + `NotificationPreferences` |
| `backend/notification/migrations/004_report_frequency.sql` | 1 | Add `report_frequency` column |
| `backend/notification/src/handlers.rs` | 1,3,4,5 | Extend `update_preferences`, add `fetch_report_data`, update `send_report` with HTML, add `send_daily_report` |
| `backend/notification/src/email_template.rs` | 4 | New — HTML email templates |
| `backend/notification/src/main.rs` | 3,5 | Add routes for report-data, daily-report, weekly-report |
| `frontend/lib/screens/parent_dashboard_screen.dart` | 1,2,8 | Sync to backend, real streak, premium gating, preview button |
| `frontend/lib/providers/app_providers.dart` | 2 | Add `userStreakProvider` |
| `docker-compose.prod.yml` | 6,7 | Add `notification-cron` sidecar, add `SENDGRID_API_KEY` env |

---

## Timeline

| Phase | Duration | Dependency |
|-------|----------|------------|
| 1. Frontend → Backend sync | 1 day | None |
| 2. Fix streak on dashboard | 0.5 day | None |
| 3. Report data aggregator | 1.5 days | None |
| 4. HTML email template | 1 day | Phase 3 |
| 5. Daily report endpoint | 0.5 day | Phase 3, 4 |
| 6. Cron scheduler | 0.5 day | Phase 5 |
| 7. SendGrid setup + deploy | 0.5 day | Phase 1-6 |
| 8. Report preview in app | 0.5 day | Phase 3 |
| **Total** | **6 days** | |

Phases 1, 2, 3 can run in parallel. Phases 4-6 depend on 3. Phase 7 depends on all. Phase 8 is optional polish.

**Parallel tracks:**
- Track A: Phase 1 + 2 (frontend) — 1.5 days
- Track B: Phase 3 + 4 + 5 (backend) — 3 days
- Join: Phase 6 + 7 + 8 — 1.5 days
- **Critical path: 4.5 days**

---

## Premium Gating Rules

| Feature | Free | Premium |
|---------|------|---------|
| In-app parent dashboard | ✅ Full access | ✅ Full access |
| Daily email report | ❌ Locked | ✅ |
| Weekly email report | ❌ Locked | ✅ |
| Report preview in app | ✅ Can preview once | ✅ Unlimited |
| Report history | ❌ | ✅ |

Implementation: `parent_dashboard_screen.dart` checks `userTierProvider`. Email prefs section shows lock icon for free users. Tapping lock → paywall modal or `/pricing` route.

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| SendGrid domain verification fails | Medium | Cloudflare DNS — need access. Fallback: use SendGrid's single sender verification (no DNS) |
| Service-to-service calls fail in Docker | Low | Use Docker service names (`http://progress-service:3000`), add retry + timeout |
| Email goes to spam | Medium | Set up SPF, DKIM, DMARC in Cloudflare DNS. SendGrid guides through this |
| SendGrid free tier limit (100/day) | Low | With 50 fake users + low real users, fine for now. Switch to paid or SES when >50 daily subscribers |
| Cron sidecar crashes | Low | `restart: unless-stopped` + healthcheck |
| User has no progress data | Medium | Template handles empty state: "Bé chưa học bài nào hôm nay" / "Bé chưa học bài nào tuần này" |

---

## Open Questions

1. **SendGrid account** — do you already have one, or need to create? (Free tier is enough to start)
2. **Cloudflare DNS access** — needed for SendGrid domain verification (SPF/DKIM records). Same blocker as www DNS fix.
3. **Email language** — should we detect from user's locale, or always send Vietnamese? (Current plan: detect from user locale preference)
4. **Report time** — daily at 20:00 ICT OK? Or different time parents prefer?
5. **Child name in email** — we have user name but not a separate "child name" field. Use username? Add child_name to user profile?

---

## Acceptance Criteria

- [ ] Parent enters email in app → email saved to backend `notification_preferences`
- [ ] Free users see locked email prefs, premium users can enable
- [ ] Dashboard shows real streak from progress API
- [ ] `POST /api/notifications/send-weekly-report` sends branded HTML email with real data
- [ ] `POST /api/notifications/send-daily-report` sends branded HTML email with real data
- [ ] Cron triggers daily at 20:00 ICT and weekly Sunday 09:00 ICT
- [ ] Email contains: lessons completed, stars earned, current streak, subject progress bars, new achievements
- [ ] Email has unsubscribe link
- [ ] `email_logs` table records every sent email
- [ ] End-to-end test: parent enables weekly → cron triggers → email received with data