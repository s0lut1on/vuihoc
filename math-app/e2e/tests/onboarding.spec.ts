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
});

test.describe('Route guards (unauthenticated)', () => {
  test('home redirects to login', async ({ page }) => {
    await page.goto('/home');
    await expect(page).toHaveURL(/login/);
  });

  test('lesson page redirects to login', async ({ page }) => {
    await page.goto('/lesson/numbers/lesson_n1');
    await expect(page).toHaveURL(/login/);
  });

  test('celebration page redirects to login', async ({ page }) => {
    await page.goto('/celebration');
    await expect(page).toHaveURL(/login/);
  });

  test('parent dashboard redirects to login', async ({ page }) => {
    await page.goto('/parent-dashboard');
    await expect(page).toHaveURL(/login/);
  });

  test('profile page redirects to login', async ({ page }) => {
    await page.goto('/profile');
    await expect(page).toHaveURL(/login/);
  });
});
