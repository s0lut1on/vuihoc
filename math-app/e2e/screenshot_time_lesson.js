const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });

  try {
    // Step 1: Login as guest
    await page.goto('http://localhost:8082/login');
    console.log('At login page');

    // Click the first button that looks like a guest login (Tiếp tục không đăng nhập)
    const buttons = await page.$$('button');
    for (const btn of buttons) {
      const text = await btn.textContent();
      if (text \u0026\u0026 text.toLowerCase().includes('không đăng nhập')) {
        console.log('Clicking guest button:', text.trim());
        await btn.click();
        break;
      }
    }

    await page.waitForTimeout(1000);
    console.log('URL after login:', page.url());

    // Step 2: Welcome page - select persona and start
    if (page.url().includes('/welcome')) {
      console.log('On welcome page, selecting persona...');

      // Click on a persona card
      const personaCards = await page.$$('[class*="card"]');
      if (personaCards.length \u003e 0) {
        await personaCards[0].click();
        await page.waitForTimeout(500);
      }

      // Click start button
      const startBtn = await page.$('text=/Bắt đầu|bắt đầu|Tiếp tục/i');
      if (startBtn) {
        await startBtn.click();
        await page.waitForTimeout(1000);
      }
    }

    // Step 3: If on assessment, just navigate away
    console.log('URL before going to lesson:', page.url());

    // Step 4: Navigate directly to the time lesson
    await page.goto('http://localhost:8082/lesson/measurement/m_time0001');
    await page.waitForTimeout(3000);
    console.log('URL at lesson:', page.url());

    // Take screenshot of the full page
    await page.screenshot({ path: '/tmp/time_lesson_full.png' });
    console.log('Screenshot saved to /tmp/time_lesson_full.png');

    // Also take a screenshot of just the visual area (center of page)
    await page.screenshot({ path: '/tmp/time_lesson_visual.png', clip: { x: 440, y: 180, width: 400, height: 300 } });
    console.log('Visual area screenshot saved to /tmp/time_lesson_visual.png');

  } catch (e) {
    console.error('Error:', e.message);
    // Take screenshot of whatever is on screen
    try {
      await page.screenshot({ path: '/tmp/time_lesson_error.png' });
      console.log('Error screenshot saved to /tmp/time_lesson_error.png');
    } catch (_) {}
  }

  await browser.close();
})();
