import { appUrl } from '../utils/config';
import { test, expect } from '@playwright/test';

test.describe('API health checks', () => {
  test('all backend services respond 200', async ({ request }) => {
    const services = [
      { name: 'auth', path: '/api/auth/health' },
      { name: 'content', path: '/api/content/health' },
      { name: 'users', path: '/api/users/health' },
      { name: 'progress', path: '/api/progress/health' },
      { name: 'notifications', path: '/api/notifications/health' },
      { name: 'media', path: '/api/media/health' },
      { name: 'question-bank', path: '/api/questions/health' },
    ];

    for (const svc of services) {
      const res = await request.get(svc.path);
      expect(res.status(), `${svc.name} health`).toBe(200);
      const body = await res.json();
      expect(body.success).toBe(true);
      expect(body.data.status).toBe('ok');
    }
  });

  test('progress health returns ok', async ({ request }) => {
    const res = await request.get('/api/progress/health');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.status).toBe('ok');
  });

  test('content health returns ok', async ({ request }) => {
    const res = await request.get('/api/content/health');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.status).toBe('ok');
  });
});

test.describe('Web smoke tests', () => {
  test('login page loads', async ({ page }) => {
    const response = await page.goto(appUrl('/login'));
    expect(response?.status()).toBe(200);
    await expect(page).toHaveTitle(/Học Toán Vui|math_app/i);
  });
});
