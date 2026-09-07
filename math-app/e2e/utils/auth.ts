/**
 * Auth helpers. Installs the mock backend, performs guest sign-in via the
 * in-app Guest button, and waits for the app to navigate to /home.
 *
 * The Flutter web app uses GoRouter with HTML5 history, so page.url()
 * reflects the current route after navigation.
 */
import type { Page } from '@playwright/test';
import { installMockBackend, MockBackendOptions } from './mockBackend';
import { waitForFlutterReady, waitForRoute, enableAccessibility } from './wait';
import { appUrl } from './config';
import { FACEBOOK_FANPAGE_URL } from './fixtures';

export async function setupApp(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  await installMockBackend(page, opts);
}

export async function gotoLogin(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  await setupApp(page, opts);
  await page.goto(appUrl('/login'));
  await waitForFlutterReady(page);
  await enableAccessibility(page);
}

export async function signInAsGuest(page: Page, opts: MockBackendOptions = {}): Promise<void> {
  await gotoLogin(page, opts);

  const guestByA11y = page.locator('flt-semantics[aria-label*="Continue without signing in"], flt-semantics[aria-label*="Tiếp tục"]');
  try {
    await guestByA11y.first().waitFor({ state: 'attached', timeout: 10_000 });
    await guestByA11y.first().click();
  } catch {
    // a11y tree unavailable — fall back to tapping the Guest button location
    const vp = page.viewportSize() ?? { width: 375, height: 812 };
    await page.mouse.click(vp.width / 2, vp.height * 0.75);
  }
  await waitForRoute(page, /\/home/);
}

export async function signOut(page: Page): Promise<void> {
  await page.evaluate(() => {
    try { localStorage.clear(); } catch { /* ignore */ }
  });
  await page.goto(appUrl('/login'));
}

export { FACEBOOK_FANPAGE_URL };

export async function recordRequests(
  page: import('@playwright/test').Page,
  action: () => Promise<void>,
): Promise<string[]> {
  const urls: string[] = [];
  page.on('request', (req) => urls.push(req.url()));
  await action();
  return urls;
}
