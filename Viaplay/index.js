const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: false,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  // Grab data from all series
  await page.goto('https://viaplay.com/us-en/series/all');
  await page.getByRole('button', { name: 'Popular' }).click();
  await page.getByRole('link', { name: 'Last added' }).click();
  await page.waitForTimeout(15000); // wait for 15 seconds
  // Grab data from all movies
  await page.goto('https://viaplay.com/us-en/movies/all');
  await page.getByRole('button', { name: 'Popular' }).click();
  await page.getByRole('link', { name: 'Last added' }).click();
  await page.waitForTimeout(15000); // wait for 15 seconds
  await context.storageState({ path: 'auth/cookies.json' });
  // ---------------------
  await context.close();
  await browser.close();
})();
