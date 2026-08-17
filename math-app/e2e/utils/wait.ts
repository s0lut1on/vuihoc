/**
 * Wait helpers for Flutter web. The app renders to CanvasKit so there's
 * no DOM. We wait for the Flutter glass-pane element which is always
 * present once main.dart.js has loaded.
 */
import type { Page, Locator } from '@playwright/test';

export const FLUTTER_GLASS_PANE = 'flt-glass-pane';
export const FLUTTER_SEMANTICS = 'flt-semantics';

export async function waitForFlutterReady(page: Page, timeoutMs = 30_000): Promise<void> {
  await page.waitForSelector(FLUTTER_GLASS_PANE, { timeout: timeoutMs, state: 'attached' });
}

export async function enableAccessibility(page: Page): Promise<void> {
  const placeholder = page.locator('flt-semantics-placeholder');
  if ((await placeholder.count()) === 0) return;
  try {
    await placeholder.first().dispatchEvent('click');
  } catch {
    // a11y already enabled or placeholder missing — non-fatal
  }
}

export async function waitForSemantics(page: Page, timeoutMs = 10_000): Promise<void> {
  await page.waitForSelector(FLUTTER_SEMANTICS, { timeout: timeoutMs, state: 'attached' });
}

/** Returns the semantics element hosting Flutter's a11y tree, or null. */
export function semanticsHost(page: Page): Locator {
  return page.locator(FLUTTER_SEMANTICS);
}

/** Wait until a specific URL path is reached. GoRouter updates the
 * browser URL via History API so this works for in-app navigation. */
export async function waitForRoute(page: Page, pathRegex: RegExp, timeoutMs = 10_000): Promise<void> {
  await page.waitForURL(pathRegex, { timeout: timeoutMs });
}

/** Wait for the page to be quiet (no in-flight requests). */
export async function waitForNetworkIdle(page: Page, timeoutMs = 5_000): Promise<void> {
  await page.waitForLoadState('networkidle', { timeout: timeoutMs });
}
