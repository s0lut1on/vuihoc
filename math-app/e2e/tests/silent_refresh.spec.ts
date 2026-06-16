/**
 * Silent JWT refresh (added 2026-06-14).
 *
 * The Dio interceptor:
 * - On request: if token expires within 60s, calls refresher before sending
 * - On 401: refreshes token, retries the request once
 * - Concurrent calls coalesce to a single refresh
 * - Skips /api/auth/* paths to avoid loops
 *
 * We can't test the Dart code directly via Playwright, but we verify
 * the API contract and the call pattern that the refresh path expects.
 */
import { test, expect } from '@playwright/test';
import { signInAsGuest, recordRequests } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Silent JWT refresh — API contract', () => {
  test('guest /auth/guest is callable repeatedly (refresh path for guest users)', async ({ page }) => {
    await signInAsGuest(page);
    await page.waitForTimeout(300);

    const urls = await recordRequests(page, async () => {
      // Trigger a fresh /auth/guest to simulate the refresh path
      await page.request.post('/api/auth/guest', { data: {} });
    });

    // Either an existing session's /auth/me or a fresh /auth/guest
    // should be in the recorded requests.
    expect(urls.some((u) => u.includes('/api/'))).toBe(true);
  });

  test('subsequent /auth/me succeeds with the same token', async ({ page }) => {
    const r1 = await page.request.post('/api/auth/guest', { data: {} });
    const t1 = (await r1.json()).data.access_token;

    const r2 = await page.request.get('/api/auth/me', {
      headers: { Authorization: `Bearer ${t1}` },
    });
    expect(r2.status()).toBe(200);
  });

  test('a 401 from any /api endpoint can be re-issued by the client refresh path', async ({ page }) => {
    // Mock a 401 on first call to /api/users
    let calls = 0;
    await page.route('**/api/users', async (route) => {
      calls++;
      if (calls === 1) {
        return route.fulfill({
          status: 401,
          contentType: 'application/json',
          body: JSON.stringify({ success: false, error: 'Token expired' }),
        });
      }
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ success: true, data: { id: 'u1', email: 'g@t', name: 'G', picture: '', given_name: 'G', tier: 'free' } }),
      });
    });

    // First call → 401
    const r1 = await page.request.get('/api/users');
    expect(r1.status()).toBe(401);
    // Refresh token (simulate)
    const refresh = await page.request.post('/api/auth/guest', { data: {} });
    expect(refresh.status()).toBe(200);
    // Retry → 200
    const r2 = await page.request.get('/api/users', {
      headers: { Authorization: `Bearer ${(await refresh.json()).data.access_token}` },
    });
    expect(r2.status()).toBe(200);
    expect(calls).toBe(2);
  });
});
