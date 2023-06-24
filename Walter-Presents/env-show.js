const { chromium } = require('playwright');
let fs = require('fs');

let series_name = process.env.TARGET;
console.log('<== TARGET = ' + series_name);

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto('https://www.pbs.org/show/' + series_name);
  try {
    for (let i = 0; i < 100; i++) {
      await page
        .locator('#splide01')
        .getByRole('button', { name: 'Next slide' })
        .click({ timeout: 1000 });
      await page.waitForTimeout(1500); // wait for 1.5 seconds
    }
    console.log('<== ' + series_name + ' Not enough "Next slide" clicks!');
  } catch {}
  const raw_html = await page.content();
  fs.writeFile(
    series_name + '-show.html',
    '<!-- Data from https://www.pbs.org/show/' +
      series_name +
      ' -->\n\n' +
      raw_html +
      '\n',
    (err) => {
      if (err) throw err;
      console.log('==> Done writing ' + series_name + '-show.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
