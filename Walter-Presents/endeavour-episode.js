const { chromium } = require('playwright');
let fs = require('fs');

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto('https://www.pbs.org/video/episode-1-prelude-be5191/');
  const description = await page
    .locator('//*[@id="maincontent"]/div[1]/article/div/div[1]/p[3]')
    .innerText();
  fs.writeFile(
    'endeavour-episode.html',
    '<!-- Data from https://www.pbs.org/video/episode-1-prelude-be5191/ -->\n' +
      description +
      '\n',
    (err) => {
      if (err) throw err;
      console.log('==> Done writing endeavour-episode.html');
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
