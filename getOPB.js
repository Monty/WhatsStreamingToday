const { chromium } = require('playwright');
let fs = require('fs');

let series_URL = process.env.TARGET;
let output_file = process.env.RAW_HTML;

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  console.log('\n==> Processing ' + series_URL);
  await page.goto(series_URL);
  try {
    for (let i = 0; i < 100; i++) {
      await page
        .locator('#splide01')
        .getByRole('button', { name: 'Next slide' })
        .click({ timeout: 1000 });
      await page.waitForTimeout(1500); // wait for 1.5 seconds
    }
    console.error('==> ' + series_URL + ' Not enough clicks!');
  } catch {}
  const raw_html = await page.content();
  fs.writeFile(
    output_file,
    '<!-- Data from ' +
      series_URL +
      ' -->\n\n' +
      raw_html +
      '\n',
    (err) => {
      // It's normal to throw an error from running out of clicks
      if (err) throw err;
      console.log('==> Completed ' + series_URL);
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
