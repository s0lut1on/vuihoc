const { chromium } = require('playwright');

const pages = [
  { path: '/login',                out: 'flutter_login.png',       name: 'login' },
  { path: '/welcome',              out: 'flutter_welcome.png',     name: 'welcome' },
  { path: '/assessment',           out: 'flutter_assessment.png',  name: 'assessment' },
  { path: '/home',                 out: 'flutter_home.png',        name: 'home' },
  { path: '/subject/numbers',      out: 'flutter_subject.png',     name: 'subject' },
  { path: '/lesson/numbers/n1',    out: 'flutter_lesson.png',      name: 'lesson' },
  { path: '/language-lesson/vietnamese/vn_l1', out: 'flutter_lang_lesson.png', name: 'lang_lesson' },
  { path: '/celebration?stars=3&persona=achiever', out: 'flutter_celebration.png', name: 'celebration' },
  { path: '/parent-dashboard',     out: 'flutter_pin.png',         name: 'pin' },
  { path: '/parent-dashboard/main', out: 'flutter_parent.png',    name: 'parent' },
  { path: '/profile',              out: 'flutter_profile.png',     name: 'profile' },
  { path: '/review',               out: 'flutter_review.png',      name: 'review' },
  { path: '/achievements',         out: 'flutter_achievements.png', name: 'achievements' },
  { path: '/leaderboard',          out: 'flutter_leaderboard.png', name: 'leaderboard' },
];

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  for (const p of pages) {
    try {
      await page.goto(`http://localhost:9997/?demo=true#${p.path}`, { waitUntil: 'load', timeout: 15000 });
      await page.waitForTimeout(3500);
      await page.screenshot({ path: `/home/s0lut1on/project/learning/math/math-app/design-html/${p.out}` });
      console.log(`OK  ${p.name}`);
    } catch (e) {
      console.log(`ERR ${p.name}: ${e.message.split('\n')[0]}`);
    }
  }
  await ctx.close(); await browser.close();
})();
