/**
 * Base URL helpers for E2E tests.
 *
 * Prod serves the Flutter app under `/app/` while APIs live at the origin
 * root (`/api/...`). Local dev serves both at `http://localhost:8082`.
 * `WEB_BASE` prefixes browser page URLs; `API_BASE` prefixes API calls.
 * `API_BASE` strips a trailing `/app` so `https://.../app` targets the same
 * origin root for APIs.
 */
export const WEB_BASE = (process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:8082').replace(/\/$/, '');
export const API_BASE = WEB_BASE.replace(/\/app$/, '') || WEB_BASE;

export function appUrl(path: string): string {
  return `${WEB_BASE}${path}`;
}

export function apiUrl(path: string): string {
  return `${API_BASE}${path}`;
}
