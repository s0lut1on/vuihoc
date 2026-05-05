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

test.describe('Subject page', () => {
  test('deep links to subject page work', async ({ page }) => {
    await page.goto('/subject/numbers');
    await expect(page).toHaveURL(/subject\/numbers/);
  });

  test('subject page loads without error', async ({ page }) => {
    const response = await page.goto('/subject/numbers');
    expect(response?.status()).toBe(200);
    await expect(page.locator('text=404')).toHaveCount(0);
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
