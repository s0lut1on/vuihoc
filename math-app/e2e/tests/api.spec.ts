import { test, expect } from '@playwright/test';

const BASE = 'http://localhost:8082';

test.describe('Content API', () => {
  test('get curriculum returns subjects', async ({ request }) => {
    const res = await request.get(`${BASE}/api/content/curriculum`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    if (body.data.length > 0) {
      expect(body.data[0]).toHaveProperty('subject_id');
      expect(body.data[0]).toHaveProperty('subject_vi');
      expect(body.data[0]).toHaveProperty('subject_en');
    }
  });

  test('get subjects returns summaries', async ({ request }) => {
    const res = await request.get(`${BASE}/api/content/subjects`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(Array.isArray(body.data)).toBe(true);
    for (const s of body.data) {
      expect(s).toHaveProperty('id');
      expect(s).toHaveProperty('name_vi');
      expect(s).toHaveProperty('name_en');
      expect(s).toHaveProperty('lesson_count');
    }
  });

  test('get lesson by id returns lesson data or 404', async ({ request }) => {
    const res = await request.get(`${BASE}/api/content/lesson/lesson_001`);
    const body = await res.json();
    expect(body).toHaveProperty('success');
  });
});

test.describe('Question Bank API', () => {
  test('mastery endpoint returns response', async ({ request }) => {
    const studentId = '00000000-0000-0000-0000-000000000000';
    const kcId = '00000000-0000-0000-0000-000000000000';
    const res = await request.get(`${BASE}/api/questions/mastery/${studentId}/${kcId}`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('success');
  });
});

test.describe('Auth API', () => {
  test('health returns service info', async ({ request }) => {
    const res = await request.get(`${BASE}/api/auth/health`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.service).toBe('auth');
    expect(body.data.status).toBe('ok');
  });
});
