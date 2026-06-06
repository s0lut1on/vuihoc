# Feature Implementation Plans

## 1. Daily Practice Reminder (Push Notification)
**Goal**: Drive retention via daily streak reminders sent at 7 PM if user hasn't practiced.

### Backend Changes
- **notification-service**: Add FCM/web push integration
  - Add `firebase_messaging` dependency (or use direct FCM HTTP API)
  - New table `push_subscriptions` (user_id, fcm_token, platform, created_at)
  - New endpoint `POST /api/notifications/subscribe` — store FCM token
  - New endpoint `POST /api/notifications/unsubscribe` — remove token
  - Background cron job (every hour): query users with no progress today, send reminder

### Frontend Changes
- **LoginScreen / WelcomeScreen**: Request notification permission after login
  - Use `firebase_messaging` web SDK to get FCM token
  - Call `POST /api/notifications/subscribe` with token
- **SettingsScreen**: Toggle "Daily reminders" on/off

### Database Migration
```sql
CREATE TABLE push_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    fcm_token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Docker/Infra
- Add `FIREBASE_SERVER_KEY` to `.env` (for FCM HTTP v1 API)

### Effort: 2-3 days

---

## 2. Achievement/Badge System
**Goal**: Gamification — kids earn badges for milestones.

### Backend Changes
- **progress-service**: Add achievement tracking
  - New table `achievements` (id, user_id, badge_type, earned_at, is_new)
  - New table `badge_definitions` (id, badge_type, name, description, icon, threshold)
  - New endpoint `GET /api/progress/achievements/:user_id`
  - New endpoint `POST /api/progress/achievements/:user_id/:badge_type/mark-read`
  - Logic hooks in existing endpoints:
    - After `POST /api/progress/complete` → check thresholds, insert badges

### Badge Types
| Badge | Trigger |
|---|---|
| first_lesson | Complete any lesson |
| streak_3 | 3-day streak |
| streak_7 | 7-day streak |
| streak_30 | 30-day streak |
| star_collector_10 | Earn 10 total stars |
| star_collector_50 | Earn 50 total stars |
| geometry_master | Complete all Geometry lessons |
| speed_demon | Complete lesson in <2 min |
| night_owl | Practice after 8 PM |
| early_bird | Practice before 7 AM |

### Frontend Changes
- **CelebrationScreen**: Show badge popup if new badge earned
- **HomeScreen**: Badge row below stats (tap to see all)
- **New Screen**: `AchievementsScreen` — grid of all badges (locked/unlocked)

### Effort: 3-4 days

---

## 3. Parent Weekly Report (Email)
**Goal**: Auto-email parents a weekly progress summary.

### Backend Changes
- **notification-service**: Add email sending capability
  - Add `lettre` crate (SMTP) or integrate SendGrid/AWS SES API
  - New cron job (Sundays at 8 AM): generate report per user
  - New table `email_logs` (id, user_id, email_type, sent_at, status)
  - New endpoint `POST /api/notifications/send-report` (admin/manual trigger)

### Report Content (Vietnamese)
```
Chào [parent_name],

Tuần này [child_name] đã:
- Hoàn thành [X] bài học
- Đạt [Y] sao ⭐
- Streak hiện tại: [Z] ngày 🔥
- Môn mạnh nhất: [subject]
- Bài học khó nhất: [lesson_name]

Xem chi tiết: https://sekklings.com/parent-dashboard
```

### Frontend Changes
- **ParentDashboardScreen**: Add "Gửi báo cáo qua email" button
- **SettingsScreen**: Email preference toggle

### Database Migration
```sql
ALTER TABLE users ADD COLUMN parent_email TEXT;
ALTER TABLE users ADD COLUMN email_reports_enabled BOOLEAN DEFAULT true;
```

### Effort: 2-3 days

---

## 4. Wrong Answer Review (Practice Mistakes)
**Goal**: Adaptive learning — let kids practice questions they got wrong.

### Backend Changes
- **question_bank-service**: Track wrong answers
  - New table `wrong_answers` (id, user_id, exercise_id, lesson_id, subject, wrong_count, last_wrong_at)
  - Modify `POST /api/questions/check` → if wrong, upsert `wrong_answers`
  - New endpoint `GET /api/questions/review/:user_id` → returns exercises with wrong_count > 0
  - New endpoint `POST /api/questions/review/:user_id/:exercise_id/clear` → mark as mastered

### Frontend Changes
- **HomeScreen**: Add "Ôn tập lỗi" card (only shows if wrong_answers exist)
- **New Screen**: `ReviewScreen` — similar to `LessonScreen` but pulls from review pool
  - Shows "Bạn đã làm sai [N] lần" hint
  - On correct answer → call clear endpoint, remove from pool

### Effort: 3-4 days

---

## 5. Leaderboard (Classroom/Friends)
**Goal**: Social motivation through peer competition.

### Backend Changes
- **user-service**: Add classroom support
  - New field `users.classroom_code` (nullable, 6-char random string)
  - New endpoint `POST /api/users/classroom/join` (body: {code})
  - New endpoint `POST /api/users/classroom/leave`
  - New endpoint `GET /api/users/classroom/leaderboard` → top 10 by weekly stars

- **progress-service**: Weekly aggregation
  - Materialized view or query: `SUM(stars) WHERE completed_at > NOW() - INTERVAL '7 days'`

### Frontend Changes
- **WelcomeScreen / HomeScreen**: "Tham gia lớp học" input (6-char code)
- **HomeScreen**: Leaderboard card showing top 3 classmates
- **New Screen**: `LeaderboardScreen` — full table with avatars, weekly stars, rank

### Effort: 3-4 days

---

## 6. Offline Mode (PWA Service Worker)
**Goal**: App works on unstable Vietnam mobile networks.

### Frontend Changes
- **Flutter Web**: Integrate `workbox` or custom service worker
  - Cache strategy: Cache-first for static assets, Network-first for API
  - Cache last 10 unlocked lessons in IndexedDB via `idb` package
  - Queue progress updates when offline, sync on reconnect
- **New Service**: `OfflineSyncService`
  - `queueProgressUpdate(lessonId, stars)` → stores in IndexedDB
  - `syncPending()` → batch sends when online
  - Listen to `window.ononline` event

### Backend Changes
- **progress-service**: Batch update endpoint
  - `POST /api/progress/batch` → accepts array of `{lesson_id, stars, completed_at}`
  - Idempotent (ignore duplicates by lesson_id + completed_at)

### UX Changes
- **LessonScreen**: Show offline indicator (cloud icon with slash)
- **CelebrationScreen**: If offline, show "Kết quả sẽ đồng bộ khi có mạng"

### Effort: 5-7 days (complex)

---

## 7. Voice Hints / Text-to-Speech
**Goal**: Kids ages 5-7 can hear questions if they can't read well.

### Frontend Changes
- **LessonScreen**: Add speaker icon next to question text
  - Tap → reads question aloud using Web Speech API (`window.speechSynthesis`)
  - Use Vietnamese voice: `speechSynthesis.getVoices().find(v => v.lang === 'vi-VN')`
  - Fallback to Google TTS API if browser voice unavailable
- **SettingsScreen**: Toggle "Đọc câu hỏi" on/off
- **ExerciseWidget**: Add `onSpeakQuestion()` callback

### Browser Support
```dart
import 'dart:html' as html;

void speak(String text) {
  final utterance = html.SpeechSynthesisUtterance(text);
  utterance.lang = 'vi-VN';
  utterance.rate = 0.9; // Slightly slower for kids
  html.window.speechSynthesis?.speak(utterance);
}
```

### Backend Changes
- None (client-side only)

### Effort: 1-2 days

---

## 8. Admin Content CMS
**Goal**: Admin panel to CRUD lessons/exercises without deploying code.

### Backend Changes
- **content-service**: Add admin endpoints (protected by admin JWT role)
  - `POST /api/content/admin/subjects` — create subject
  - `PUT /api/content/admin/subjects/:id` — update subject
  - `POST /api/content/admin/lessons` — create lesson
  - `PUT /api/content/admin/lessons/:id` — update lesson
  - `POST /api/content/admin/exercises` — create exercise
  - `PUT /api/content/admin/exercises/:id` — update exercise
  - `DELETE /api/content/admin/lessons/:id` — soft delete

- **auth-service**: Add role-based auth
  - New field `users.role` enum: `['child', 'parent', 'admin']`
  - JWT claim `role: "admin"` for admin users
  - New middleware `require_admin` → returns 403 for non-admins

### Frontend Changes
- **New Route**: `/admin` (protected by `require_admin` guard)
- **AdminDashboardScreen**:
  - Sidebar: Subjects, Lessons, Exercises, Users
  - Table views with create/edit/delete buttons
  - WYSIWYG-like exercise builder (form-based)

### Database Migration
```sql
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'child';
UPDATE users SET role = 'admin' WHERE email = 'your-email@example.com';
```

### Effort: 5-7 days

---

## Priority Recommendation

| Rank | Feature | Effort | Impact | Reason |
|---|---|---|---|---|
| 1 | Voice Hints (#7) | 1-2 days | Very High | Critical for 5-7 age group; minimal backend work |
| 2 | Practice Mistakes (#4) | 3-4 days | High | Improves learning outcomes; differentiator |
| 3 | Achievement/Badges (#2) | 3-4 days | High | Gamification drives retention |
| 4 | Daily Reminder (#1) | 2-3 days | High | Simple retention mechanism |
| 5 | Weekly Report (#3) | 2-3 days | Medium | Keeps parents looped in |
| 6 | Leaderboard (#5) | 3-4 days | Medium | Social feature; needs user base first |
| 7 | Offline Mode (#6) | 5-7 days | Medium | Complex; nice-to-have for Vietnam networks |
| 8 | Admin CMS (#8) | 5-7 days | Low | Only needed when scaling content |
