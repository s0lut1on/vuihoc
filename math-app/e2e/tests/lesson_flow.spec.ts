import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = 'http://localhost:8082';

async function guestLoginApi(request: APIRequestContext): Promise<string> {
  const res = await request.post(`${BASE}/api/auth/guest`, { data: {} });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.success).toBe(true);
  return body.data.access_token;
}

test.describe('Lesson Flow — API', () => {
  test('curriculum returns subjects', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/curriculum`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThanOrEqual(3);
  });

  test('subjects returns summaries', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/subjects`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThanOrEqual(3);
  });

  test('lesson by id returns data or 404', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/lesson/lesson_n1`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const body = await res.json();
    expect(body).toHaveProperty('success');
  });
});

