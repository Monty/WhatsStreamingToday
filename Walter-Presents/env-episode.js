const { chromium } = require('playwright');
let fs = require('fs');

let episode_URL = process.env.TARGET;
console.log('==> TARGET = ' + episode_URL);

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto(episode_URL);
  const description = await page
    .locator('//*[@id="maincontent"]/div[1]/article/div/div[1]/p[3]')
    .innerText();
  const rating = await page
    .locator('//*[@id="maincontent"]/div[1]/article/div/div[1]/div[2]/p[3]')
    .innerText();
  fs.appendFile(
    'env-episode.txt',
    'URL="' +
      episode_URL +
      '"\n' +
      'Description="' +
      description +
      '"\n' +
      rating +
      '\n\n',
    (err) => {
      if (err) throw err;
      console.log('==> Done writing env-episode.txt');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
