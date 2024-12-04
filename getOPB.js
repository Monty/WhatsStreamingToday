const { chromium } = require('playwright');
let fs = require('fs');

let series_URL = process.env.TARGET;
let output_file = process.env.RAW_HTML;

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: 'auth/cookies.json',
  });
  const page = await context.newPage();
  console.log('\n==> Processing ' + series_URL);

  try {
    // Attempt to navigate to the URL
    await page.goto(series_URL, { timeout: 30000 });
    await page.waitForTimeout(10000); // wait for 10 seconds
    const raw_html = await page.content();
    fs.writeFile(
      output_file,
      '<!-- Data from ' + series_URL + ' -->\n\n' + raw_html + '\n',
      (err) => {
        if (err) {
          console.error('==> Error writing to RAW_HTML file:', err);
        } else {
          console.log('==> Completed ' + series_URL);
        }
      }
    );
  } catch (error) {
    // Log timeout or other navigation errors
    console.error('==> Error during page navigation:', error.message);
  } finally {
    // Ensure resources are cleaned up
    await context.close();
    await browser.close();
  }
})();
