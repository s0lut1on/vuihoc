import { test, expect, APIRequestContext } from '@playwright/test';

const BASE = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:8082';

async function guestLoginApi(request: APIRequestContext): Promise<string> {
  const res = await request.post(`${BASE}/api/auth/guest`, { data: {} });
  expect(res.status()).toBe(200);
  const body = await res.json();
  expect(body.success).toBe(true);
  return body.data.access_token;
}

test.describe('Grade Levels API', () => {
  test('Grade 1 curriculum returns original lessons', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/curriculum?grade=1`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBeGreaterThanOrEqual(4);

    const numbers = body.data.find((s: any) => s.subject_id === 'numbers');
    expect(numbers).toBeDefined();
    expect(numbers.lessons.length).toBeGreaterThanOrEqual(40);
  });

  test('Grade 2 curriculum returns harder lessons', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/curriculum?grade=2`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);

    const numbers = body.data.find((s: any) => s.subject_id === 'numbers');
    expect(numbers).toBeDefined();
    expect(numbers.lessons.length).toBeGreaterThanOrEqual(40);

    const firstLesson = numbers.lessons[0];
    expect(firstLesson.id).toMatch(/^g2_/);
    expect(firstLesson.difficulty).toBeGreaterThanOrEqual(2);
  });

  test('Grade 2 subjects show correct lesson counts', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/subjects?grade=2`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);

    const numbers = body.data.find((s: any) => s.id === 'numbers');
    expect(numbers.lesson_count).toBeGreaterThanOrEqual(40);
  });

  test('Grade 3 curriculum returns empty or future lessons', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/content/curriculum?grade=3`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
  });

  test('Default grade is 1 when no param provided', async ({ request }) => {
    const token = await guestLoginApi(request);
    const defaultRes = await request.get(`${BASE}/api/content/curriculum`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const grade1Res = await request.get(`${BASE}/api/content/curriculum?grade=1`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const defaultBody = await defaultRes.json();
    const grade1Body = await grade1Res.json();

    expect(defaultBody.data.length).toBe(grade1Body.data.length);
  });

  test('User profile includes grade field', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/users`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data).toHaveProperty('grade');
    expect(body.data.grade).toBeGreaterThanOrEqual(1);
    expect(body.data.grade).toBeLessThanOrEqual(3);
  });

  test('User can update grade', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.post(`${BASE}/api/users/grade`, {
      headers: { Authorization: `Bearer ${token}` },
      data: { grade: 2 },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.grade).toBe(2);
  });

  test('Language service Grade 2 curriculum', async ({ request }) => {
    const token = await guestLoginApi(request);
    const res = await request.get(`${BASE}/api/language/curriculum?grade=2`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data.curriculum)).toBe(true);
    expect(body.data.curriculum.length).toBeGreaterThanOrEqual(2);
  });
});
