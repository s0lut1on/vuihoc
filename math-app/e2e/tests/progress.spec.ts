import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:8082';

async function guestLoginApi(request: APIRequestContext): Promise<string> {
  const res = await request.post(`${BASE}/api/auth/guest`, { data: {} });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.success).toBe(true);
  return body.data.access_token;
}

test.describe('Progress API — daily limit', () => {
  test('daily-limit returns count=0 limit=50 for new guest', async ({ request }) => {
    const token = await guestLoginApi(request);
    const meRes = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const meBody = await meRes.json();
    const userId = meBody.data.id;

    const res = await request.get(`${BASE}/api/progress/daily-limit/${userId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.count).toBe(0);
    expect(body.data.limit).toBe(50);
    expect(body.data.has_reached_limit).toBe(false);
  });

  test('update progress creates a record', async ({ request }) => {
    const token = await guestLoginApi(request);
    const meRes = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const userId = (await meRes.json()).data.id;

    const res = await request.post(`${BASE}/api/progress`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { user_id: userId, lesson_id: 'lesson_test_001', stars: 3, completed: true },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.completed).toBe(true);
    expect(body.data.stars).toBeGreaterThanOrEqual(3);
  });

  test('daily-limit count increments after completion', async ({ request }) => {
    const token = await guestLoginApi(request);
    const meRes = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const userId = (await meRes.json()).data.id;

    await request.post(`${BASE}/api/progress`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { user_id: userId, lesson_id: `lesson_${Date.now()}`, stars: 3, completed: true },
    });

    const res = await request.get(`${BASE}/api/progress/daily-limit/${userId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.data.count).toBeGreaterThanOrEqual(1);
  });

  test('get streak returns initial zero for new user', async ({ request }) => {
    const token = await guestLoginApi(request);
    const meRes = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const userId = (await meRes.json()).data.id;

    const res = await request.get(`${BASE}/api/progress/streak/${userId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.current_streak).toBe(0);
    expect(body.data.best_streak).toBe(0);
  });

  test('get user progress returns array for new user', async ({ request }) => {
    const token = await guestLoginApi(request);
    const meRes = await request.get(`${BASE}/api/auth/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const userId = (await meRes.json()).data.id;

    const res = await request.get(`${BASE}/api/progress/${userId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
  });
});
