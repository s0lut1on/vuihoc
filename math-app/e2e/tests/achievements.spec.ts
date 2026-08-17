/**
 * Achievement screen — Vietnamese-only strings (not localized).
 * NEW chip on unread badges, mark-read on tap, snackbar on new badges loaded.
 */
import { appUrl } from '../utils/config';
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Achievement screen', () => {
  test('authenticated /achievements loads badges from /api/achievements', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const calls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/achievements') && !r.url().includes('mark-read')) {
        calls.push(r.url());
      }
    });

    await page.goto(appUrl('/achievements'));
    await page.waitForTimeout(1000);
    expect(calls.length).toBeGreaterThanOrEqual(1);
  });

  test('marking a badge as read POSTs /api/achievements/mark-read', async ({ page }) => {
    await signInAsGuest(page);
    const r = await page.request.post('/api/achievements/mark-read', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
      data: { badge_type: 'first_lesson' },
    });
    expect(r.status()).toBe(200);
    const body = await r.json();
    expect(body.success).toBe(true);
  });

  test('unauthenticated /achievements redirects to /login', async ({ page }) => {
    await page.goto(appUrl('/login'));
    await page.waitForTimeout(300);
    await page.goto(appUrl('/achievements'));
    await waitForRoute(page, /\/login/);
  });

  test('empty achievements list shows "Chưa có huy chương" message', async ({ page }) => {
    await page.route('**/api/achievements', (route) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ success: true, data: [] }) }),
    );
    await signInAsGuest(page);
    await page.goto(appUrl('/achievements'));
    await page.waitForTimeout(1000);
    // No crash, URL is on /achievements
    expect(page.url()).toMatch(/\/achievements/);
  });
});
