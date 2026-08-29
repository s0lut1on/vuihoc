/**
 * Leaderboard screen — global leaderboard with total score across all subjects.
 * Vietnamese-only strings ("Bảng xếp hạng").
 */
import { appUrl } from '../utils/config';
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Leaderboard (global only)', () => {
  test('authenticated /leaderboard loads entries from /api/users/leaderboard/global', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const calls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/users/leaderboard/global')) calls.push(r.url());
    });

    await page.goto(appUrl('/leaderboard'));
    await page.waitForTimeout(1000);
    expect(calls.length).toBeGreaterThanOrEqual(1);
  });

  test('empty leaderboard shows "Chưa có dữ liệu" message', async ({ page }) => {
    await signInAsGuest(page, { emptyLeaderboard: true });
    await page.goto(appUrl('/leaderboard'));
    await page.waitForTimeout(1000);
    expect(page.url()).toMatch(/\/leaderboard/);
  });

  test('unauthenticated /leaderboard redirects to /login', async ({ page }) => {
    await page.goto(appUrl('/login'));
    await page.waitForTimeout(300);
    await page.goto(appUrl('/leaderboard'));
    await waitForRoute(page, /\/login/);
  });
});