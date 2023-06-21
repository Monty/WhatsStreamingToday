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
  await page.goto('https://www.pbs.org/show/astrid/');
  const show = await page.content();
  fs.writeFile(
    'astrid-show.html',
    '<!-- Data from https://www.pbs.org/show/astrid/ -->\n\n' + show + '\n',
    (err) => {
      if (err) throw err;
      console.log('==> Done writing astrid-show.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
