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
  await page.goto('https://www.pbs.org/show/astrid/episodes/');
  const episodes = await page.content();
  fs.writeFile(
    'astrid-episodes.html',
    '<!-- Data from https://www.pbs.org/show/astrid/episodes/ -->\n\n' +
      episodes +
      '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writting astrid-episodes.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
