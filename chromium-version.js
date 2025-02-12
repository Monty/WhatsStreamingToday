const { chromium } = require("playwright");

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });

  const version = await browser.version();

  console.log("Chromium version:", version);

  await browser.close();
})();
