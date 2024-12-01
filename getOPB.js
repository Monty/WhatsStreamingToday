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
  await page.waitForTimeout(10000); // wait for 10 seconds
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
