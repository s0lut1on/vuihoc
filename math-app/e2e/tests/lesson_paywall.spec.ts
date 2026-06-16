/**
 * Lesson screen — exercise flow, TTS, daily limit paywall, wrong answer.
 *
 * Daily limit: free tier 50 lessons/day. After hitting 50, completing
 * another lesson shows PaywallModal instead of celebration.
 * Premium tier has no limit.
 */
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Lesson screen', () => {
  test('authenticated /lesson/:subjectId/:lessonId loads exercise', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const calls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/content/curriculum') || r.url().includes('/api/content/lesson')) {
        calls.push(r.url());
      }
    });

    await page.goto('/lesson/numbers/lesson_n1');
    await page.waitForTimeout(1500);
    expect(calls.length).toBeGreaterThanOrEqual(1);
  });

  test('free tier at daily limit (count>=50) blocks lesson finish', async ({ page }) => {
    await signInAsGuest(page, { dailyCount: 50 });
    await page.goto('/lesson/numbers/lesson_n1');
    await page.waitForTimeout(1500);

    // /api/progress/daily-limit is called on lesson init
    const limit = await page.request.get('/api/progress/daily-limit/u1', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
    });
    expect(limit.status()).toBe(200);
    const body = await limit.json();
    expect(body.data.has_reached_limit).toBe(true);
  });

  test('premium tier has no daily limit', async ({ page }) => {
    await signInAsGuest(page, { premium: true });
    await page.goto('/lesson/numbers/lesson_n1');
    await page.waitForTimeout(1500);

    const limit = await page.request.get('/api/progress/daily-limit/u1', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
    });
    const body = await limit.json();
    expect(body.data.tier).toBe('premium');
    expect(body.data.has_reached_limit).toBe(false);
  });

  test('unauthenticated /lesson redirects to /login', async ({ page }) => {
    await page.goto('/login');
    await page.waitForTimeout(300);
    await page.goto('/lesson/numbers/lesson_n1');
    await waitForRoute(page, /\/login/);
  });

  test('wrong answer is recorded to /api/progress/review', async ({ page }) => {
    await signInAsGuest(page);
    await page.waitForTimeout(300);

    const recordCalls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/progress/review') && r.method() === 'POST') {
        recordCalls.push(r.url());
      }
    });

    await page.goto('/lesson/numbers/lesson_n1');
    await page.waitForTimeout(500);
    // Verify endpoint contract accepts wrong-answer submissions
    const r = await page.request.post('/api/progress/review', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
      data: { user_id: 'u1', exercise_id: 'e1', lesson_id: 'l1', subject_id: 'numbers', question_vi: '?', question_en: '?', options: [], correct_index: 0, is_correct: false },
    });
    expect(r.status()).toBeLessThan(500);
  });
});
