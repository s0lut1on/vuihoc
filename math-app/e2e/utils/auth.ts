/**
 * Auth helpers. Installs the mock backend, performs guest sign-in via the
 * in-app Guest button, and waits for the app to navigate to /home.
 *
 * The Flutter web app uses GoRouter with HTML5 history, so page.url()
 * reflects the current route after navigation.
 */
import type { Page } from '@playwright/test';
import { installMockBackend, MockBackendOptions } from './mockBackend';
import { waitForFlutterReady, waitForRoute } from './wait';
import { FACEBOOK_FANPAGE_URL } from './fixtures';

export async function setupApp(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  await installMockBackend(page, opts);
}

/**
 * Loads the app at /login. Waits for Flutter to be ready.
 * Doesn't sign in; the page is at the login screen.
 */
export async function gotoLogin(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  await setupApp(page, opts);
  await page.goto('/login');
  await waitForFlutterReady(page);
}

/**
 * Clicks the Guest sign-in button via the Flutter semantics tree (a11y
 * label set by the screen on the Guest button) and waits for the app
 * to navigate to /home.
 *
 * Falls back to tapping the center-bottom of the visible canvas
 * (where the Guest button is on mobile) if a11y is not available.
 */
export async function signInAsGuest(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  await setupApp(page, opts);
  await page.goto('/login');
  await waitForFlutterReady(page);

  // Try a11y selector first; if not present, use a coordinate click.
  // The Guest button is the last primary button on the login screen.
  const guestByA11y = page.locator('flt-semantics[aria-label*="Continue without signing in"], flt-semantics[aria-label*="Tiếp tục"]');
  if ((await guestByA11y.count()) > 0) {
    await guestByA11y.first().click();
  } else {
    // Mobile fallback: tap center horizontally, ~75% down the viewport
    const vp = page.viewportSize() ?? { width: 375, height: 812 };
    await page.mouse.click(vp.width / 2, vp.height * 0.75);
  }
  await waitForRoute(page, /\/home/);
}

export async function signOut(page: Page): Promise<void> {
  // The Profile screen's logout handler clears localStorage and
  // navigates to /login. Easiest: clear storage + reload.
  await page.evaluate(() => {
    try { localStorage.clear(); } catch {}
  });
  await page.goto('/login');
}

/**
 * Records all network requests for the duration of a callback.
 * Useful for asserting which API calls were made.
 */
export async function recordRequests(
  page: Page,
  body: () => Promise<void>,
): Promise<string[]> {
  const urls: string[] = [];
  const handler = (req: import('@playwright/test').Request) => {
    if (req.url().includes('/api/')) urls.push(req.url());
  };
  page.on('request', handler);
  try { await body(); } finally { page.off('request', handler); }
  return urls;
}

export { FACEBOOK_FANPAGE_URL };
