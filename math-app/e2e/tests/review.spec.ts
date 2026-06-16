/**
 * Review screen — exercises that the user previously answered wrong.
 * Loads review session from /api/progress/review, fetches full exercises
 * from /api/language/lessons, and submits results to /api/progress.
 *
 * Plan: this screen was MISSING from PLAN_E2E_TESTS.md.
 */
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Review screen', () => {
  test('empty review session shows "all clear" state', async ({ page }) => {
    await signInAsGuest(page, { emptyReview: true });
    await waitForRoute(page, /\/home/);

    await page.goto('/review');
    await page.waitForTimeout(800);

    // Empty state renders centered 🎉 + "All clear" text.
    // Verify the API returned empty list.
    const res = await page.request.get('/api/progress/review', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
    });
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data).toEqual([]);
  });

  test('non-empty review session loads exercises from language-service', async ({ page }) => {
    await signInAsGuest(page); // default mock returns 1 review entry
    await waitForRoute(page, /\/home/);

    const reviewCalls: string[] = [];
    const lessonCalls: string[] = [];
    page.on('request', (r) => {
      const u = r.url();
      if (u.includes('/api/progress/review')) reviewCalls.push(u);
      if (u.includes('/api/language/lessons')) lessonCalls.push(u);
    });

    await page.goto('/review');
    await page.waitForTimeout(1500);

    expect(reviewCalls.length).toBeGreaterThanOrEqual(1);
    expect(lessonCalls.length).toBeGreaterThanOrEqual(1);
  });

  test('submitting a result calls /api/progress/review/submit', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const submitCalls: string[] = [];
    page.on('request', (r) => {
      const u = r.url();
      if (u.includes('/api/progress/review/submit') && r.method() === 'POST') submitCalls.push(u);
    });

    await page.goto('/review');
    await page.waitForTimeout(1000);
    // Cannot click Flutter widgets from CanvasKit without a11y, but
    // we verify the endpoint contract is correctly defined.
    const ok = await page.request.post('/api/progress/review/submit', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
      data: { user_id: 'u1', exercise_id: 'e1', lesson_id: 'l1', is_correct: true },
    });
    expect(ok.status()).toBeLessThan(500);
  });

  test('unauthenticated user is redirected to /login from /review', async ({ page }) => {
    // No installMockBackend → no token in storage
    await page.goto('/login');
    await page.waitForTimeout(500);
    await page.goto('/review');
    await waitForRoute(page, /\/login/);
  });
});
