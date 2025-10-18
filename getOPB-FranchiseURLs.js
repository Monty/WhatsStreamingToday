// Get a list of URLs from a https://www.pbs.org/franchise/*/ BROWSE_URL
// Append them to SHOW_URLS

const { chromium } = require("playwright");
const fs = require("fs");
const SHOW_URLS = process.env.SHOW_URLS;
const BROWSE_URL = process.env.BROWSE_URL;
const RED_ERROR = "\x1b[31mError\x1b[0m";

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
      // Remove any potentially invalid filename characters
      const validName = name.replace(/[^a-zA-Z0-9 ]/g, "");
      // Replace any spaces with underscores
      const cleanName = validName.replace(/ /g, "_");
      return `${url}\t${name}\t${cleanName}`;
    })
    .join("\n");

  try {
    fs.appendFileSync(SHOW_URLS, tsv, "utf8");
  } catch (err) {
    console.error(`==> ${RED_ERROR} appending to ${SHOW_URLS}`, err);
  }
  console.log(`==> Added ${uniqueShows.length} URLs to ${SHOW_URLS}`);

  await browser.close();
})();
