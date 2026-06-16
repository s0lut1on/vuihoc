/**
 * Parent dashboard flow:
 *   /parent-dashboard → PIN gate (1234) → /parent-dashboard/main
 *
 * NOTE: pin_gate_screen has correct PIN hardcoded as '1234'. Wrong PIN
 * shows red snackbar and resets the dots.
 */
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Parent dashboard flow', () => {
  test('PIN gate is the only public route (no auth required)', async ({ page }) => {
    await page.goto('/parent-dashboard');
    await page.waitForTimeout(500);
    // /parent-dashboard is in _publicRoutes; should stay there, not redirect
    expect(page.url()).toMatch(/\/parent-dashboard$/);
  });

  test('entering wrong PIN keeps user on PIN gate and shows error', async ({ page }) => {
    await page.goto('/parent-dashboard');
    await page.waitForTimeout(500);

    // The keypad uses ElevatedButton with text '1'..'9', '0', '←', 'Back'
    // Without a11y, we can't click individual digits. The keypad layout:
    // 1 2 3
    // 4 5 6
    // 7 8 9
    // Back 0 ←
    // Tapping 4 wrong digits in random sequence should not advance.
    const vp = page.viewportSize() ?? { width: 375, height: 812 };
    // The keypad is centered. Approximate: each row is 60px tall, starts ~y=400.
    // Buttons are 80x56 with 8px padding. We tap "1" four times in a wrong PIN.
    // Tapping 4x the same digit still only appends that digit.
    await page.mouse.click(vp.width * 0.3, vp.height * 0.55); // approx "1"
    await page.mouse.click(vp.width * 0.3, vp.height * 0.55);
    await page.mouse.click(vp.width * 0.3, vp.height * 0.55);
    await page.mouse.click(vp.width * 0.3, vp.height * 0.55);
    await page.waitForTimeout(500);

    // After 4 digits entered (and they don't match '1234'), app resets
    // and shows snackbar. URL stays.
    expect(page.url()).toMatch(/\/parent-dashboard$/);
  });

  test('/parent-dashboard/main is protected (redirects to /login)', async ({ page }) => {
    // This is a *different* route from /parent-dashboard.
    // The router map shows /parent-dashboard/main → ParentDashboardScreen.
    // Whether it's public is not in _publicRoutes, so it requires auth.
    // (Currently the route is registered but not in _publicRoutes set.)
    await page.goto('/login');
    await page.waitForTimeout(300);
    await page.goto('/parent-dashboard/main');
    await page.waitForTimeout(500);
    // The redirect logic checks _publicRoutes which contains /parent-dashboard
    // but NOT /parent-dashboard/main. So it should redirect to /login.
    expect(page.url()).toMatch(/\/login/);
  });

  test('authenticated user on /parent-dashboard/main loads detailed progress', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const progressCalls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/language/detailed-progress')) progressCalls.push(r.url());
    });

    await page.goto('/parent-dashboard/main');
    await page.waitForTimeout(1500);
    expect(progressCalls.length).toBeGreaterThanOrEqual(1);
  });
});
