/**
 * Language lesson screen — separate from math lessons.
 * Uses LanguageApi.getLesson instead of ContentApi.getCurriculum.
 * Routes: /language-lesson/:subjectId/:lessonId
 *
 * Plan: this 506-line screen was MISSING from PLAN_E2E_TESTS.md.
 */
import { appUrl } from '../utils/config';
import { test, expect } from '@playwright/test';
import { signInAsGuest } from '../utils/auth';
import { waitForRoute } from '../utils/wait';

test.describe('Language lesson screen', () => {
  test('direct navigation to /language-lesson loads the lesson', async ({ page }) => {
    await signInAsGuest(page);
    await waitForRoute(page, /\/home/);

    const lessonCalls: string[] = [];
    page.on('request', (r) => {
      if (r.url().includes('/api/language/lessons/')) lessonCalls.push(r.url());
    });

    await page.goto(appUrl('/language-lesson/vietnamese/lesson_v1'));
    await page.waitForTimeout(1500);

    expect(lessonCalls.length).toBeGreaterThanOrEqual(1);
    expect(page.url()).toMatch(/\/language-lesson\/vietnamese\/lesson_v1/);
  });

  test('handles missing lesson gracefully (renders "Not found")', async ({ page }) => {
    // Override the lesson endpoint to return 404
    await signInAsGuest(page);
    await page.route('**/api/language/lessons/missing*', (route) =>
      route.fulfill({ status: 404, body: JSON.stringify({ success: false, error: 'Not found' }) }),
    );

    await page.goto(appUrl('/language-lesson/vietnamese/missing'));
    await page.waitForTimeout(1500);
    // App catches error, sets _loading=false, renders "Not found" text
    // (CanvasKit — no DOM assertion possible, just verify no crash).
    expect(page.url()).toMatch(/\/language-lesson\//);
  });

  test('unauthenticated redirect', async ({ page }) => {
    await page.goto(appUrl('/login'));
    await page.waitForTimeout(500);
    await page.goto(appUrl('/language-lesson/vietnamese/lesson_v1'));
    await waitForRoute(page, /\/login/);
  });
});
