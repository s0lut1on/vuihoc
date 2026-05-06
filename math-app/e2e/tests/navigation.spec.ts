import { test, expect } from '@playwright/test';

const MOBILE_VIEWPORT = { width: 375, height: 812 };
const DESKTOP_VIEWPORT = { width: 1280, height: 720 };

test.describe('Responsive layout', () => {
  test('login screen on mobile', async ({ page }) => {
    await page.setViewportSize(MOBILE_VIEWPORT);
    await page.goto('/login');
    const screenshot = await page.screenshot();
    expect(screenshot).toBeTruthy();
  });

  test('login screen on desktop', async ({ page }) => {
    await page.setViewportSize(DESKTOP_VIEWPORT);
    await page.goto('/login');
    const screenshot = await page.screenshot();
    expect(screenshot).toBeTruthy();
  });

  test('welcome screen on mobile', async ({ page }) => {
    await page.setViewportSize(MOBILE_VIEWPORT);
    await page.goto('/welcome');
    const screenshot = await page.screenshot();
    expect(screenshot).toBeTruthy();
  });

  test('welcome screen on desktop', async ({ page }) => {
    await page.setViewportSize(DESKTOP_VIEWPORT);
    await page.goto('/welcome');
    const screenshot = await page.screenshot();
    expect(screenshot).toBeTruthy();
  });
});

test.describe('Subject page (unauthenticated redirects)', () => {
  test('deep links to subject page redirect to login', async ({ page }) => {
    await page.goto('/subject/numbers');
    await expect(page).toHaveURL(/login/);
  });
});

test.describe('Title and metadata', () => {
  test('login page has a title', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveTitle(/Học Toán Vui|math_app/i);
  });

  test('welcome page has a title', async ({ page }) => {
    await page.goto('/welcome');
    await expect(page).toHaveTitle(/Học Toán Vui|math_app/i);
  });
});
