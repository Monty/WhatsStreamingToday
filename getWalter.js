const { chromium } = require('playwright');
let fs = require('fs');
let date_id = process.env.DATE_ID;
let raw_html = process.env.RAW_HTML;
let browse_url = process.env.BROWSE_URL;

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  await page.goto(browse_url);
  const shows = await page.content();
  fs.writeFile(
    raw_html,
    '<!-- Data from ' + browse_url + ' -->\n\n' + shows + '\n',
    (err) => {
      if (err) throw err;
      console.log('==> Done writing ' + raw_html);
    }
  );

  await context.storageState({ path: 'auth/cookies.json' });
  // ---------------------
  await context.close();
  await browser.close();
})();
