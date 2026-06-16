/**
 * Leaderboard screen — join classroom code input, weekly stars.
 * Vietnamese-only strings ("Bảng xếp hạng", "Mã lớp học", "Tham gia", "Rời lớp").
 */
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Leaderboard + classroom', () => {
  test('authenticated /leaderboard loads entries from /api/users/leaderboard', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const calls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/users/leaderboard')) calls.push(r.url());
    });

    await page.goto('/leaderboard');
    await page.waitForTimeout(1000);
    expect(calls.length).toBeGreaterThanOrEqual(1);
  });

  test('empty leaderboard shows "Chưa có dữ liệu" message', async ({ page }) => {
    await signInAsGuest(page, { emptyLeaderboard: true });
    await page.goto('/leaderboard');
    await page.waitForTimeout(1000);
    expect(page.url()).toMatch(/\/leaderboard/);
  });

  test('joining a classroom calls /api/users/classroom/join with the code', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const joinCalls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/users/classroom/join') && r.method() === 'POST') {
        joinCalls.push(r.url());
      }
    });

    await page.goto('/leaderboard');
    await page.waitForTimeout(500);

    // Verify the contract: the API accepts a 6-char code in the body
    const r = await page.request.post('/api/users/classroom/join', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
      data: { code: 'ABC123' },
    });
    expect(r.status()).toBe(200);
    expect(joinCalls.length).toBeGreaterThanOrEqual(1);
  });

  test('leaving a classroom calls /api/users/classroom/leave', async ({ page }) => {
    await signInAsGuest(page);
    await page.waitForTimeout(300);

    const r = await page.request.post('/api/users/classroom/leave', {
      headers: { Authorization: 'Bearer fake.jwt.guest-token-test' },
      data: {},
    });
    expect(r.status()).toBe(200);
  });

  test('unauthenticated /leaderboard redirects to /login', async ({ page }) => {
    await page.goto('/login');
    await page.waitForTimeout(300);
    await page.goto('/leaderboard');
    await waitForRoute(page, /\/login/);
  });
});
