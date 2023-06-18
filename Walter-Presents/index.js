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
  await page.goto('https://www.pbs.org/franchise/walter-presents/');
  await page.getByRole('button', { name: 'Load More' }).click();
  await page.getByRole('button', { name: 'Load More' }).click();
  await page.getByRole('button', { name: 'Load More' }).click();
  await page.waitForTimeout(5000); // wait for 5 seconds
  const shows = await page.content();
  fs.writeFile(
    'allShows.html',
    '<!-- Data from https://www.pbs.org/franchise/walter-presents/ -->\n\n' +
      shows +
      '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writting allShows.html');
    }
  );

  await context.storageState({ path: 'auth/cookies.json' });
  // ---------------------
  await context.close();
  await browser.close();
})();
