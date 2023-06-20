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
  try {
    for (let i = 0; i < 5; i++) {
      await page
        .getByRole('button', { name: 'Load More' })
        .click({ timeout: 1000 });
      await page.waitForTimeout(1500); // wait for 1.5 seconds
    }
    console.log('<== Walter Presents: Not enough "Load More" clicks!');
  } catch {}
  const shows = await page.content();
  fs.writeFile(
    raw_html,
    '<!-- Data from ' + browse_url + ' -->\n\n' + shows + '\n',
    (err) => {
      if (err) throw err;
      console.log('<== Done writing ' + raw_html);
    }
  );

  await context.storageState({ path: 'auth/cookies.json' });
  // ---------------------
  await context.close();
  await browser.close();
})();
