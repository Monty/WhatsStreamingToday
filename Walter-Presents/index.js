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
  try {
    for (let i = 0; i < 5; i++) {
      await page.getByRole('button', { name: 'Load More' }).click({ timeout: 1000 });
      await page.waitForTimeout(1500); // wait for 1.5 seconds
    }
    console.log('<== Walter Presents: Not enough "Load More" clicks!');
  } catch {}
  const shows = await page.content();
  fs.writeFile(
    'allShows.html',
    '<!-- Data from https://www.pbs.org/franchise/walter-presents/ -->\n\n' +
      shows +
      '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writing allShows.html');
    }
  );

  await context.storageState({ path: 'auth/cookies.json' });
  // ---------------------
  await context.close();
  await browser.close();
})();
