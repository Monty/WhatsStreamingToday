const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto('https://www.pbs.org/franchise/walter-presents/');
  await page
    .getByRole('navigation')
    .locator('div')
    .filter({ hasText: 'Sign in to keep track' })
    .getByRole('button')
    .click();
  await page.getByRole('link', { name: 'Sign in with Email' }).click();
  await page.getByPlaceholder('Email Address').click();
  await page.getByPlaceholder('Email Address').fill('My_Email_Address');
  await page.getByPlaceholder('Password').click();
  await page.getByPlaceholder('Password').fill('My_Password');
  await page.getByRole('button', { name: 'Sign in with Email' }).click();
  await page.waitForTimeout(15000); // wait for 15 seconds
  await context.storageState({ path: 'auth/cookies.json' });
  // ---------------------
  await context.close();
  await browser.close();
})();
