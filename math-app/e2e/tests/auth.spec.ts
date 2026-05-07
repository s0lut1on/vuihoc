import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:8082';

async function guestLoginApi(request: APIRequestContext): Promise<string> {
  const res = await request.post(`${BASE}/api/auth/guest`, { data: {} });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.success).toBe(true);
  return body.data.access_token;
}

test.describe('Auth API', () => {
  test('guest login returns token', async ({ request }) => {
    const token = await guestLoginApi(request);
    expect(typeof token).toBe('string');
    expect(token.length).toBeGreaterThan(10);
  });

  test('auth/me returns user data', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.email).toMatch(/^guest_/);
  });
});

test.describe('Route guards — unauthenticated', () => {
  test('home redirects to login', async ({ page }) => {
    await page.goto('/home');
    await expect(page).toHaveURL(/login/);
  });

  test('lesson page redirects to login', async ({ page }) => {
    await page.goto('/lesson/numbers/lesson_n1');
    await expect(page).toHaveURL(/login/);
  });

  test('profile redirects to login', async ({ page }) => {
    await page.goto('/profile');
    await expect(page).toHaveURL(/login/);
  });

  test('subject redirects to login', async ({ page }) => {
    await page.goto('/subject/numbers');
    await expect(page).toHaveURL(/login/);
  });

  test('celebration redirects to login', async ({ page }) => {
    await page.goto('/celebration');
    await expect(page).toHaveURL(/login/);
  });
});

test.describe('Route guards — public routes always accessible', () => {
  test('login page loads', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveURL(/login/);
  });

  test('welcome page loads', async ({ page }) => {
    await page.goto('/welcome');
    await expect(page).toHaveURL(/welcome/);
  });

  test('parent-dashboard loads', async ({ page }) => {
    await page.goto('/parent-dashboard');
    await expect(page).toHaveURL(/parent-dashboard/);
  });
});

test.describe('Route guards — authenticated user redirects', () => {
  test('auth/me with guest token returns valid user', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.name).toBeTruthy();
  });
});
