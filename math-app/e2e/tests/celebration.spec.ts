/**
 * Celebration screen — stars, persona-specific message, gems reward, gamer bonus.
 * CelebrationScreen requires `extra` params (stars, persona, subjectId, lessonId).
 */
import { appUrl } from '../utils/config';
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';
import { FREE_USER } from '../utils/fixtures';

test.describe('Celebration screen', () => {
  test('unauthenticated /celebration redirects to /login (no extras)', async ({ page }) => {
    await page.goto(appUrl('/login'));
    await page.waitForTimeout(300);
    await page.goto(appUrl('/celebration'));
    await waitForRoute(page, /\/login/);
  });

  test('authenticated user can navigate to /celebration', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);
    // Flutter passes extra via state.extra (not URL params). Without
    // a11y-driven click, we verify the route resolves without error.
    await page.goto(appUrl('/celebration'));
    await page.waitForTimeout(500);
    expect(page.url()).toMatch(/\/celebration/);
  });

  test('gamer persona loads celebration route without crash', async ({ page }) => {
    await signInAsGuest(page, { user: { ...FREE_USER, persona: 'gamer' } });
    await page.goto(appUrl('/celebration'));
    await page.waitForTimeout(500);
  });
});
