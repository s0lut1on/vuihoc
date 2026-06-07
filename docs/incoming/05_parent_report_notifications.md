# Plan: Parent Report Notifications

## Problem
Parents must manually open `ParentDashboardScreen` to see progress. No proactive weekly summary exists.

## Goal
Email weekly progress summaries to parents (or show in-app if email not configured). Summarize: exercises completed, accuracy rate, streak, weak areas.

## Scope

### MVP (2-3 days)
- **Backend**: Extend `notification-service` (or `user-service`) with email delivery:
  - New table `email_preferences` (user_id, parent_email, frequency: 'weekly' | 'never').
  - Scheduled job (cron or Tokio `tokio-cron-scheduler`) every Sunday at 19:00 UTC+7 (Sunday evening Vietnam time).
  - Job queries `progress-service` for each user's last 7 days of activity.
  - Generates HTML email template (bilingual vi/en) with:
    - Total exercises completed
    - Accuracy % (correct / total)
    - Current streak
    - Top 3 weak sub-subjects (by wrong_count)
    - CTA link to `/parent-dashboard`
- **Backend**: New endpoint `POST /api/user/email-preferences` — update parent email + frequency.
- **Frontend**: Add email input + toggle to `ParentDashboardScreen` settings tab.

### V2
- In-app notification bell with weekly summary card (no email needed).
- Push notification via Firebase Cloud Messaging.

## Affected Files

### Backend
- `math-app/backend/notification-service/src/main.rs` — add cron scheduler
- `math-app/backend/notification-service/src/email.rs` — new, SMTP or SendGrid integration
- `math-app/backend/notification-service/src/db.rs` — `email_preferences` table
- `math-app/backend/notification-service/migrations/` — add migration
- `math-app/backend/user-service/src/router.rs` — `/email-preferences` endpoint

### Frontend
- `math-app/frontend/lib/screens/parent_dashboard_screen.dart` — settings tab with email input
- `math-app/frontend/lib/services/user_api.dart` — add `updateEmailPreferences()`

## Effort Estimate
- **Backend**: 2 days (scheduler + email template + SendGrid/SMTP setup)
- **Frontend**: 0.5 day (settings UI)
- **Testing**: 0.5 day (dry-run scheduler, spam filter check)

## Risks
- SMTP credentials must be stored securely (VPS `.env` or AWS SES).
- Email deliverability: use DKIM/SPF if custom domain; otherwise SendGrid.
- GDPR / privacy: only send to opted-in addresses; store consent.

## Success Criteria
- [ ] Parent receives weekly email on Sunday 7 PM with child's progress summary.
- [ ] Email includes link to `https://sekklings.com/parent-dashboard`.
- [ ] Unsubscribe link works (sets frequency to 'never').
