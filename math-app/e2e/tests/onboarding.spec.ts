import { test, expect } from '@playwright/test';

test.describe('Page loads', () => {
  test('login page returns 200 with title', async ({ page }) => {
    const response = await page.goto('/login');
    expect(response?.status()).toBe(200);
    await expect(page).toHaveTitle(/Học Toán Vui|math_app/i);
  });

  test('welcome page loads', async ({ page }) => {
    await page.goto('/welcome');
    await expect(page).toHaveURL(/welcome/);
  });

  test('home page loads', async ({ page }) => {
    await page.goto('/home');
    await expect(page).toHaveURL(/home/);
  });

  test('lesson page loads', async ({ page }) => {
    await page.goto('/lesson/numbers/lesson_n1');
    await expect(page).toHaveURL(/lesson/);
  });

  test('celebration page loads', async ({ page }) => {
    await page.goto('/celebration');
    await expect(page).toHaveURL(/celebration/);
  });

  test('parent dashboard loads', async ({ page }) => {
    await page.goto('/parent-dashboard');
    await expect(page).toHaveURL(/parent-dashboard/);
  });

  test('pin gate loads', async ({ page }) => {
    await page.goto('/pin-gate');
    await expect(page).toHaveURL(/pin-gate/);
  });
});
