const { chromium } = require('playwright');
let fs = require('fs');

let episode_ID = process.env.TARGET;
let episode_URL = 'https://www.pbs.org/video' + episode_ID;
let output_file = process.env.AWK_EPISODES;
console.log('\n==> Processing ' + episode_ID);

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto(episode_URL);
  let description = await page
    .locator('//*[@id="maincontent"]/div[1]/article/div/div[1]/p[3]')
    .innerText();
  description = description.replaceAll('"', '\\"');
  let rating = await page
    .locator('//*[@id="maincontent"]/div[1]/article/div/div[1]/div[2]/p[3]')
    .innerText();
  rating = rating.replace('Rating: ', '');
  fs.appendFile(
    output_file,
    episode_ID +
      ' { $7="' +
      rating +
      '"; $8="' +
      description +
      '"; print; next }\n\n',
    (err) => {
      if (err) throw err;
      console.log('==> Completed ' + episode_ID);
    }
  );

  // ---------------------
  await context.close();
  await browser.close();
})();
