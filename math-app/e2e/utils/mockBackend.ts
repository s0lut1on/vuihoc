/**
 * Mock backend. Registers a default set of route handlers that the
 * Flutter app's Hive + Riverpod + Dio stack will exercise.
 *
 * Tests can override individual routes with page.route after install.
 */
import type { Page, Route } from '@playwright/test';
import { FREE_USER, PREMIUM_USER, FAKE_GUEST_TOKEN, FAKE_PREMIUM_TOKEN, MockUser } from './fixtures';

export interface MockBackendOptions {
  user?: MockUser;
  /** When true, /api/auth/guest issues a premium tier token. */
  premium?: boolean;
  /** Force the daily-limit counter to this value (>=50 → paywall). */
  dailyCount?: number;
  /** Override subjects returned for a grade. */
  subjectsByGrade?: Record<number, Array<Record<string, unknown>>>;
  /** Empty review session. */
  emptyReview?: boolean;
  /** Empty leaderboard. */
  emptyLeaderboard?: boolean;
}

function ok(data: unknown) {
  return { success: true, data };
}

function err(message: string, code = 400) {
  return { success: false, error: message, status: code };
}

const DEFAULT_SUBJECTS: Record<number, Array<Record<string, unknown>>> = {
  1: [
    { id: 'numbers', name_vi: 'Số học', name_en: 'Numbers', icon: '🔢', color: '#FFE8F0', lesson_count: 610 },
    { id: 'geometry', name_vi: 'Hình học', name_en: 'Geometry', icon: '📐', color: '#E8F5E9', lesson_count: 300 },
    { id: 'measurement', name_vi: 'Đo lường', name_en: 'Measurement', icon: '📏', color: '#FFF3E0', lesson_count: 400 },
    { id: 'logic', name_vi: 'Tư duy', name_en: 'Logic', icon: '🧩', color: '#E3F2FD', lesson_count: 400 },
  ],
  2: [
    { id: 'arithmetic_2digit', name_vi: 'Cộng trừ 2 chữ số', name_en: '2-digit arithmetic', icon: '➕', color: '#FFE8F0', lesson_count: 20 },
    { id: 'multiplication', name_vi: 'Bảng cửu chương', name_en: 'Multiplication', icon: '✖️', color: '#FFF3E0', lesson_count: 20 },
    { id: 'perimeter', name_vi: 'Chu vi', name_en: 'Perimeter', icon: '📏', color: '#E8F5E9', lesson_count: 20 },
    { id: 'time_money', name_vi: 'Thời gian & Tiền', name_en: 'Time & Money', icon: '⏰', color: '#E3F2FD', lesson_count: 20 },
    { id: 'word_problems', name_vi: 'Bài toán có lời', name_en: 'Word problems', icon: '📝', color: '#F3E5F5', lesson_count: 20 },
  ],
  3: [
    { id: 'arithmetic_3digit', name_vi: 'Cộng trừ 3 chữ số', name_en: '3-digit arithmetic', icon: '➕', color: '#FFE8F0', lesson_count: 20 },
    { id: 'multiplication', name_vi: 'Nhân 1-10', name_en: 'Multiplication', icon: '✖️', color: '#FFF3E0', lesson_count: 20 },
    { id: 'division', name_vi: 'Chia có dư', name_en: 'Division', icon: '➗', color: '#E8F5E9', lesson_count: 20 },
    { id: 'fractions', name_vi: 'Phân số', name_en: 'Fractions', icon: '½', color: '#E3F2FD', lesson_count: 20 },
    { id: 'decimals', name_vi: 'Số thập phân', name_en: 'Decimals', icon: '0.5', color: '#F3E5F5', lesson_count: 20 },
  ],
};

export async function installMockBackend(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  const user = opts.user ?? (opts.premium ? PREMIUM_USER : FREE_USER);
  const dailyCount = opts.dailyCount ?? 0;
  const subjectsByGrade = { ...DEFAULT_SUBJECTS, ...(opts.subjectsByGrade ?? {}) };
  // The mutable copy that the test can edit by triggering UI actions.
  const state: { user: MockUser; dailyCount: number } = {
    user: { ...user },
    dailyCount,
  };

  // All /api routes are intercepted. Tests can override after installMockBackend.
  await page.route('**/api/**', async (route: Route) => {
    const req = route.request();
    const url = new URL(req.url());
    const path = url.pathname.replace(/^\/api\//, '');
    const method = req.method();
    const auth = req.headers().authorization ?? '';

    // Health endpoints (used by smoke tests)
    if (path.endsWith('/health')) {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ status: 'ok' })) });
    }

    // --- AUTH ---
    if (path === 'auth/guest' && method === 'POST') {
      const token = state.user.tier === 'premium' ? FAKE_PREMIUM_TOKEN : FAKE_GUEST_TOKEN;
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok({ access_token: token, token_type: 'Bearer', expires_in: 86400 })),
      });
    }
    if (path === 'auth/me' && method === 'GET') {
      if (!auth.startsWith('Bearer ')) {
        return route.fulfill({ status: 401, contentType: 'application/json', body: JSON.stringify(err('Unauthorized')) });
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok(state.user)) });
    }

    // --- USERS ---
    if (path === 'users' && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok(state.user)) });
    }
    if (path === 'users/grade' && method === 'POST') {
      const body = JSON.parse(req.postData() ?? '{}');
      state.user = { ...state.user, grade: body.grade };
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ grade: state.user.grade })) });
    }
    if (path === 'users/leaderboard' && method === 'GET') {
      if (opts.emptyLeaderboard) return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok([])) });
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok([
          { id: 'u1', name: 'Bé A', avatar: '🐸', weekly_stars: 30 },
          { id: state.user.id, name: state.user.name, avatar: '🐸', weekly_stars: 12 },
        ])),
      });
    }
    if (path === 'users/classroom/join' && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ joined: true })) });
    }
    if (path === 'users/classroom/leave' && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ left: true })) });
    }

    // --- CONTENT ---
    if (path.startsWith('content/subjects') && method === 'GET') {
      const grade = Number(url.searchParams.get('grade') ?? state.user.grade);
      const subjects = subjectsByGrade[grade] ?? [];
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok(subjects)) });
    }
    if (path.startsWith('content/curriculum') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok([])) });
    }
    if (path.startsWith('content/lesson') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok({
          id: url.pathname.split('/').pop(),
          subject_id: 'numbers',
          title_vi: 'Bài học mẫu',
          title_en: 'Sample lesson',
          difficulty: 1,
          exercises: [
            { id: 'e1', question_vi: '1 + 1 = ?', question_en: '1 + 1 = ?', options: ['1', '2', '3'], correct: 1, hint_vi: 'Đếm', hint_en: 'Count' },
            { id: 'e2', question_vi: '2 + 2 = ?', question_en: '2 + 2 = ?', options: ['3', '4', '5'], correct: 1, hint_vi: 'Đếm', hint_en: 'Count' },
          ],
        })),
      });
    }

    // --- PROGRESS ---
    if (path.startsWith('progress/daily-limit') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok({ count: state.dailyCount, limit: 50, tier: state.user.tier, has_reached_limit: state.dailyCount >= 50 })),
      });
    }
    if (path === 'progress' && method === 'POST') {
      state.dailyCount += 1;
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ completed: true, stars: 3, count: state.dailyCount })) });
    }
    if (path === 'progress' && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok([])) });
    }
    if (path.startsWith('progress/review') && method === 'GET') {
      if (opts.emptyReview) return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok([])) });
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok([
          { exercise_id: 'e1', lesson_id: 'lesson_1', wrong_count: 2 },
        ])),
      });
    }
    if (path === 'progress/review/submit' && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ recorded: true })) });
    }
    if (path === 'progress/streak' && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ current_streak: state.user.streakDays ?? 0 })) });
    }

    // --- LANGUAGE ---
    if (path.startsWith('language/curriculum') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok([])) });
    }
    if (path.startsWith('language/sub-subjects') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok([])) });
    }
    if (path.startsWith('language/detailed-progress') && method === 'GET') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ subjects: [] })) });
    }
    if (path.startsWith('language/lessons') && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok({
          id: 'lesson_1', title_vi: 'Xin chào', title_en: 'Hello',
          exercises: [{ id: 'e1', question_vi: 'Xin chào', question_en: 'Hello', options: ['Hi', 'Bye'], correct: 0, hint_vi: '', hint_en: '' }],
        })),
      });
    }

    // --- QUESTIONS (hint bank) ---
    if (path === 'questions/hint' && method === 'POST') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok({ hint_vi: 'Gợi ý mẫu', hint_en: 'Sample hint' })),
      });
    }

    // --- ACHIEVEMENTS ---
    if (path === 'achievements' && method === 'GET') {
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(ok([
          { badge_type: 'first_lesson', earned_at: '2025-01-01', is_new: true, name: 'Bài học đầu tiên', description: 'Hoàn thành bài đầu', icon: '🌟', threshold: 1 },
        ])),
      });
    }
    if (path === 'achievements/mark-read' && method === 'POST') {
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(ok({ ok: true })) });
    }

    // Default: passthrough
    return route.continue();
  });
}
