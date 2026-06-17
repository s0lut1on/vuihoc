// Screenshot each <section> as 1280x832 PNG via Playwright + Chromium.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const HTML = 'file:///home/s0lut1on/project/learning/math/math-app/design-html/mockup.html';
const OUT = '/home/s0lut1on/project/learning/math/math-app/design-html/screenshots';
fs.mkdirSync(OUT, { recursive: true });

const SECTIONS = [
  ['01_login',         'login'],
  ['02_welcome',       'welcome'],
  ['03_assessment',    'assessment'],
  ['04_home',          'home'],
  ['05_subject',       'subject'],
  ['06_lesson',        'lesson'],
  ['07_language',      'language'],
  ['08_celebration',   'celebration'],
  ['09_pin',           'pin'],
  ['10_parent',        'parent'],
  ['11_profile',       'profile'],
  ['12_review',        'review'],
  ['13_achievements',  'achievements'],
  ['14_leaderboard',   'leaderboard'],
  ['15_paywall',       'paywall'],
];

(async () => {
  const browser = await chromium.launch();
  for (const [name, id] of SECTIONS) {
    const ctx = await browser.newContext({ viewport: { width: 1280, height: 832 }, deviceScaleFactor: 2 });
    const page = await ctx.newPage();
    await page.goto(HTML, { waitUntil: 'networkidle' });
    await page.waitForTimeout(900); // font load
    // Hide floating nav strip before screenshot
    await page.addStyleTag({ content: 'div[style*="position:fixed"]{display:none !important;}' });
    const el = await page.$(`#${id}`);
    if (!el) { console.log(`!! missing #${id}`); await ctx.close(); continue; }
    await el.scrollIntoViewIfNeeded();
    await page.waitForTimeout(250);
    const out = path.join(OUT, `${name}.png`);
    await el.screenshot({ path: out });
    console.log(`  ${name}.png`);
    await ctx.close();
  }
  await browser.close();
  console.log('done');
})();
