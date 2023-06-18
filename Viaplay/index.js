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
  // Grab data from all series
  await page.goto('https://viaplay.com/us-en/series/all');
  await page.getByRole('button', { name: 'Popular' }).click();
  await page.getByRole('link', { name: 'Last added' }).click();
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(5000); // wait for 5 seconds
  const series = await page.content();
  fs.writeFile(
    'allSeries.html',
    '<!-- Data from https://viaplay.com/us-en/series/all -->\n\n' +
      series +
      '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writting allSeries.html');
    }
  );

  // Grab data from all movies
  await page.goto('https://viaplay.com/us-en/movies/all');
  await page.getByRole('button', { name: 'Popular' }).click();
  await page.getByRole('link', { name: 'Last added' }).click();
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(2000); // wait for 2 seconds
  await page.mouse.wheel(0, 4000)
  await page.waitForTimeout(5000); // wait for 5 seconds
  await context.storageState({ path: 'auth/cookies.json' });
  const movies = await page.content();
  fs.writeFile(
    'allMovies.html',
    '<!-- Data from https://viaplay.com/us-en/movies/all -->\n\n' + movies + '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writting allMovies.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
