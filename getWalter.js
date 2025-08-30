const { chromium } = require("playwright");
const fs = require("fs");
const SHOW_URLS = process.env.SHOW_URLS;
const BROWSE_URL = process.env.BROWSE_URL;

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const page = await browser.newPage();
  await page.goto(BROWSE_URL);

  await page.waitForSelector("a.ShowPoster_show_poster__link__gzPSH img[alt]");

  const showData = await page.evaluate(() => {
    const anchors = Array.from(
      document.querySelectorAll("a.ShowPoster_show_poster__link__gzPSH"),
    );
    return anchors
      .map((a) => {
        const img = a.querySelector("img[alt]");
        const url = a.href.startsWith("http")
          ? a.href
          : `https://www.pbs.org${a.getAttribute("href")}`;
        const name = img ? img.getAttribute("alt").trim() : "";
        return { url, name };
      })
      .filter((item) => item.name && item.url);
  });

  // Deduplicate and sort by show title
  const uniqueShows = Array.from(
    new Map(showData.map((item) => [item.url, item])).values(),
  ).sort((a, b) => a.name.localeCompare(b.name, "en", { sensitivity: "base" }));

  const tsv = uniqueShows
    .map(({ url, name }) => {
      // Clean name: replace non-alphanumeric with underscores
      const cleanName = name.replace(/[^a-zA-Z0-9]/g, "_") + ".csv";
      return `${url}\t${name}\t${cleanName}`;
    })
    .join("\n");

  fs.writeFileSync(SHOW_URLS, tsv, "utf8");

  console.log(`==> Wrote ${uniqueShows.length} URLs to ` + SHOW_URLS);
  await browser.close();
})();
