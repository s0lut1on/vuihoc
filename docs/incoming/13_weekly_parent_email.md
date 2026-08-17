# Plan: Weekly Parent Email Report

## Problem
Parents must open the app to see child's progress. No proactive summary exists. The `ParentDashboardScreen` already has email input UI (text field + frequency toggle) but the backend email delivery doesn't exist.

## Goal
Send weekly progress emails every Sunday 7PM ICT. Report includes:
- Lessons completed this week (count + subjects breakdown)
- Accuracy rate (correct answers / total)
- Current streak + best streak
- Top 3 weak sub-subjects (by wrong_count)
- Stars earned this week
- Premium upsell link (for free users)

## Scope

### MVP — Backend (3-4 days)

**Email preferences** (`user-service`):
- New table `email_preferences`:
  ```sql
  CREATE TABLE email_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    parent_email VARCHAR(255) NOT NULL,
    frequency VARCHAR(20) NOT NULL DEFAULT 'never',  -- 'never' | 'weekly'
    weekly_opt_in_at TIMESTAMPTZ,  -- when user last enabled
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
  ```
- New endpoint `POST /api/users/email-preferences`:
  ```json
  { "parent_email": "me@example.com", "frequency": "weekly" }
  ```
- New endpoint `GET /api/users/email-preferences`:
  Returns current preferences

**Email sending service** (new `email-service` or extend `notification-service`):

Option A (recommended): **Extend notification-service** with SendGrid integration
- Add `SENDGRID_API_KEY` env var
- Add `email.rs` module with:
  - `send_email(to, subject, html_body)` — uses SendGrid v3 API over HTTPS (no SDK needed)
  - `generate_weekly_report(user_id, week_data)` — builds HTML from progress data
- Add `cron.rs` module with:
  - `tokio-cron-scheduler` job: every Sunday at 19:00 ICT
  - Queries progress-service for weekly stats per user
  - Sends email to opted-in parents

**Weekly report data** (progress-service):
- New endpoint `GET /api/progress/weekly-summary/:user_id?week_end=2026-07-19`:
  - Returns JSON with:
    ```json
    {
      "lessons_completed": 12,
      "subjects": [
        {"subject_id": "numbers", "completed": 5, "total": 10, "accuracy": 0.85},
        {"subject_id": "geometry", "completed": 3, "total": 10, "accuracy": 0.72}
      ],
      "current_streak": 5,
      "best_streak": 7,
      "stars_earned": 36,
      "weak_exercises": [
        {"exercise_id": "ex_n4_01", "wrong_count": 3, "question_vi": "..."}
      ],
      "tier": "free"
    }
    ```

**HTML email template** (bilingual):
```
Chào [Parent Name],

Tuần này [Child Name] đã học được [N] bài trên HocVui! 🎉

📚 Bài học đã hoàn thành: [N]
⭐ Sao kiếm được: [N]
🔥 Chuỗi học tập: [N] ngày

Môn học:
✅ Số học: [5/10 bài] — [85%]
✅ Hình học: [3/10 bài] — [72%]
...

🔴 Cần cải thiện:
- [exercise] (sai [N] lần)

👉 Xem chi tiết: https://sekklings.com/parent-dashboard

---
Nếu không muốn nhận email hàng tuần, hủy đăng ký tại đây.
```

### MVP — Frontend (0.5 day)

Already done in `ParentDashboardScreen`:
- Email text field
- Frequency toggle (never / weekly)
- Save to `LocalStorageService`

**Missing**: Wire the frontend to the backend endpoint:
- Add `UserApi.updateEmailPreferences(email, frequency)`
- Call on save instead of (or in addition to) local storage
- Show confirmation snackbar

### V2
- Email authentication (send confirmation link before enabling)
- Multiple recipients (both parents)
- Vietnamese-only / English-only email preference
- Monthly summary option
- PDF attachment with worksheet recommendations
- Unsubscribe link with one-click (already in template)

## Affected Files

### Backend
- `math-app/backend/notification/Cargo.toml` — add `tokio-cron-scheduler`, `reqwest` (SendGrid)
- `math-app/backend/notification/src/main.rs` — add cron scheduler init
- `math-app/backend/notification/src/email.rs` — new, SendGrid integration
- `math-app/backend/notification/src/cron.rs` — new, weekly report job
- `math-app/backend/notification/migrations/` — add email_preferences table
- `math-app/backend/user/src/handlers.rs` — add email-preferences endpoints
- `math-app/backend/user/src/main.rs` — add routes
- `math-app/backend/user/src/models.rs` — add `EmailPreferences`
- `math-app/backend/user/migrations/` — add email_preferences table
- `math-app/backend/progress/src/handlers.rs` — add weekly-summary endpoint

### Frontend
- `math-app/frontend/lib/screens/parent_dashboard_screen.dart` — wire save to API
- `math-app/frontend/lib/services/user_api.dart` — add `updateEmailPreferences()`, `getEmailPreferences()`

### Infra
- `math-app/math-app/.env.example` — add `SENDGRID_API_KEY`
- `math-app/math-app/docker-compose.prod.yml` — add `SENDGRID_API_KEY` env to notification-service

## Effort Estimate
- **Backend**: 3-4 days (SendGrid integration, cron job, weekly summary query, email template)
- **Frontend**: 0.5 day (wire existing UI to API)
- **Infra**: 0.5 day (SendGrid account, DKIM setup, env vars)
- **Testing**: 0.5 day
- **Total**: ~5 days

## Risks
- SendGrid requires verified sender domain. Configure SPF/DKIM for `sekklings.com`.
- Emails may land in spam. Warm up sender reputation gradually (start with 50/week).
- Cron scheduler fails silently if `notification-service` restarts. Add health check endpoint.
- Weekly summary query aggregates across all subjects — optimize with materialized view for large user base.

## Success Criteria
- [ ] Parent saves email + weekly frequency in dashboard
- [ ] Sunday 7PM ICT, parent receives email with child's weekly summary
- [ ] Email shows: lessons completed, accuracy, streak, stars, weak areas
- [ ] Unsubscribe link sets frequency to 'never'
- [ ] HTML email renders correctly in Gmail, Outlook, Yahoo Mail
- [ ] No email sent if parent never opted in
- [ ] Cron job logs success/failure for observability
