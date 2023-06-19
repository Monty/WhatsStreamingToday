const { chromium } = require('playwright');
let fs = require('fs');

let series_name = process.env.TARGET;
console.log('TARGET = ' + series_name);

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto('https://www.pbs.org/show/' + series_name);
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
      console.log('<== Done writing ' + series_name + '-show.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
