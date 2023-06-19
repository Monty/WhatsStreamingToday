const { chromium } = require('playwright');
let fs = require('fs');

(async () => {
  const browser = await chromium.launch({
    headless: false,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto('https://www.pbs.org/show/endeavour/');
  try {
    for (let i = 0; i < 11; i++) {
      await page
        .locator('#splide01')
        .getByRole('button', { name: 'Next slide' })
        .click({ timeout: 1000 });
      await page.waitForTimeout(1000); // wait for 1 seconds
    }
    console.log('<== Not enough "Next slide" clicks!');
  } catch {
  }
  const show = await page.content();
  fs.writeFile(
    'endeavour-show.html',
    '<!-- Data from https://www.pbs.org/show/endeavour/ -->\n\n' + show + '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writing endeavour-show.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
