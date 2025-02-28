/* eslint capitalized-comments: "off", no-magic-numbers: "off"
    --------
    Comments are debugging console.log statements
    Magic numbers are mostly lengths and offsets
  */

const { chromium } = require("playwright");
const fs = require("fs");

const RED = "\x1b[31m";
const NO_COLOR = "\x1b[0m";

const series_URL = process.env.TARGET;
const output_file = process.env.RAW_HTML;
const retries_file = process.env.RETRIES_FILE;
// Access the TIMEOUT environment variable, default to 1500 if not set
const timeoutDuration = parseInt(process.env.TIMEOUT, 10) || 1500;
// console.log(`==> Timeout set to ${timeoutDuration}`);

async function elementExists(page, role, ariaName) {
  const elementCount = await page.getByRole(role, { name: ariaName }).count();
  return elementCount > 0;
}

function appendToFile(headingTitle, showURL, filePath, sectionHeading) {
  fs.appendFile(filePath, sectionHeading, (err) => {
    if (err) {
      console.error(`==> Error writing to file ${filePath}:`, err);
    } else {
      console.log(`==> Completed ${headingTitle} from ${showURL}`);
    }
  });
}

function appendToRetriesFile(showURL) {
  fs.appendFile(retries_file, showURL + "\n", (err) => {
    if (err) {
      console.error(`==> Error writing to file ${retries_file}:`, err);
    } else {
      console.log(`==> Added ${showURL} to ${retries_file}`);
    }
  });
}

// Helper function to calculate the number of episodes in a season
function countEpisodes(tabData) {
  const falseEpisodes =
    tabData.split("paragraph: Providing Support for PBS.org").length - 1;
  return tabData.split("\n  - paragraph: ").length - 1 - falseEpisodes;
}

async function handleTab(page, tabName) {
  async function fetchOneSeasonWithRetries(tabName, season = null) {
    let seasonName;
    if (season && season.label) {
      seasonName = `"${season.label}" `;
    } else {
      seasonName = "";
    }
    // console.log(`tabName = ${tabName}`);
    // console.log(`seasonName = ${seasonName}`);

    const maxRetries = 5; // Maximum number of retries to get episode data
    let seasonContent;
    let retries = 0;
    while (retries < maxRetries) {
      seasonContent = await page
        .getByRole("tabpanel", { name: tabName })
        .ariaSnapshot();
      const numberOfEpisodes = countEpisodes(seasonContent);
      // console.log(`    numberOfEpisodes =  ${numberOfEpisodes}`);
      if (numberOfEpisodes === 0) {
        retries++;
        if (retries < maxRetries) {
          console.log(`    Retrying... Attempt ${retries}/${maxRetries}`);
          await page.waitForTimeout(500);
        } else {
          console.error(
            `==> [${RED}Error${NO_COLOR}] ${numberOfEpisodes} episodes in ${tabName} ` +
              `tab ${seasonName} after ${maxRetries} retries in`,
            series_URL,
          );
          // Add the series_URL to the list of URLs to be retried
          appendToRetriesFile(series_URL);
        }
      } else {
        if (retries > 0) {
          const episodeText = numberOfEpisodes !== 1 ? "episodes" : "episode";
          const retriesText = retries !== 1 ? "retries" : "retry";
          console.warn(
            `==> [Warning] Finding ${numberOfEpisodes} ${episodeText} in ` +
              `${tabName} tab ${seasonName}took ${retries} ${retriesText} in`,
            series_URL,
          );
        }
        break; // Exit loop if episodes are found
      }
    }
    return seasonContent;
  }

  if (await elementExists(page, "tab", tabName)) {
    await page.getByRole("tab", { name: tabName }).click();

    // Is there a combobox in this tab?
    const combobox = await page.getByRole("combobox").first();
    if (await combobox.isVisible()) {
      // There is a combobox
      const options = await combobox.evaluate((select) =>
        Array.from(select.options).map((option) => ({
          value: option.value,
          label: option.textContent.trim(),
        })),
      );
      const numberOfSeasons = options.length;

      for (const option of options) {
        // Select the option
        await combobox.selectOption(option.value);
        // Wait for the selected option to have the "selected" attribute
        const selectedOption = combobox.locator(
          `option[value="${option.value}"]`,
        );
        const isSelected = await selectedOption.evaluate((el) => el.selected);
        if (!isSelected) {
          console.error(
            `==> Option "${option.label}" in ${tabName} was not selected in`,
            series_URL,
          );
        }

        // Click the selected option to trigger any dependent updates
        await combobox.selectOption(option.value);
        // console.log(`Option ${option.label} was selected.`);

        // A specific waitForSelector would be better
        await page.waitForTimeout(timeoutDuration);

        // There is a combobox
        const currentSeason = await fetchOneSeasonWithRetries(tabName, {
          label: `${option.label}`,
        });
        await writeOneSeasonsEpisodesData(
          page,
          `${tabName} tab "${option.label}" of "${numberOfSeasons}"`,
          currentSeason,
        );
      }
    } else {
      // There is no combobox
      const currentSeason = await fetchOneSeasonWithRetries(tabName);
      await writeOneSeasonsEpisodesData(page, `${tabName} tab`, currentSeason);
    }
  }
}

// The sequence defining an episode
//  - paragraph:
//    - link "Love Me Some Candied Yams"
// or  - 'link "Love Me Some Candied Yams"'
//  - paragraph: S1 Ep10 | Vivian visits farms. (24m 40s)
//  - button "Add to My List":

async function writeOneSeasonsEpisodesData(page, headingTitle, snapshot) {
  const episodes = [];
  const linkCounts = new Map();
  const uniqueURLs = new Set();
  const lines = snapshot.split("\n");
  let isInParagraph = false;
  let currentLink = "";

  for (const line of lines) {
    if (line === "  - paragraph:") {
      isInParagraph = true;
      continue;
    }

    if (isInParagraph && line.match(/^ {4}- (?:')?link /)) {
      episodes.push(line);

      // Extract currentLink based on the line format
      if (line.startsWith('    - link "')) {
        currentLink = line.substring(12, line.length - 1);
      } else {
        currentLink = line.substring(13, line.length - 2);
      }
      currentLink = currentLink.replace(/\\"/g, '"');
      currentLink = currentLink.replace(/''/g, "'");
      // console.log('\n==> linkName:', currentLink);

      // Track the occurrences of currentLink
      const currentLinkCount = linkCounts.get(currentLink) || 0;
      linkCounts.set(currentLink, currentLinkCount + 1);
      // console.log('==> linkCounts:', linkCounts);
      // console.log('==> currentLinkCount:', currentLinkCount);

      // Fetch all links matching the currentLink
      const ariaLinks = await page
        .getByRole("link", { name: currentLink, exact: true })
        .all();
      // console.log('==> ariaLinks:', ariaLinks);

      for (const link of ariaLinks) {
        const aSingleURL = await link.getAttribute("href");
        if (aSingleURL) {
          uniqueURLs.add(aSingleURL);
        }
      }

      // Access the desired link by index
      // console.log('==> uniqueURLs:', uniqueURLs);
      // console.log('==> currentLinkCount:', currentLinkCount);
      const episodeURL = [...uniqueURLs][currentLinkCount];
      if (episodeURL) {
        // console.log('==> episodeURL:', episodeURL);
        episodes.push(episodeURL);
      } else {
        console.error(
          `==> Link for "${currentLink}" in`,
          `\n    ${headingTitle} not found in`,
          series_URL,
        );
      }
    }

    if (isInParagraph && line.startsWith("  - paragraph: ")) {
      episodes.push(line);
      // console.log('==> paragraph:', line);
    }

    if (isInParagraph && line.startsWith("  - button")) {
      isInParagraph = false;
      // console.log('==> uniqueURLs:', uniqueURLs);
      // console.log('==> button:', line);
      currentLink = "";
      uniqueURLs.clear();
    }
  }
  appendToFile(
    headingTitle,
    series_URL,
    output_file,
    `<!-- ${headingTitle} data from ${series_URL} ` +
      `-->\n${episodes.join("\n")}\n\n`,
  );
}

async function writeEssentialData(headingTitle, snapshot, eofString, offset) {
  let essentialData = "";
  const splitLines = snapshot.split("\n");
  const firstIndex = splitLines.indexOf(eofString);
  essentialData = splitLines.slice(0, firstIndex + offset).join("\n");
  appendToFile(
    headingTitle,
    series_URL,
    output_file,
    `<!-- ${headingTitle} data from ${series_URL} -->\n${essentialData}\n\n`,
  );
}

function removeFile(filePath) {
  fs.unlink(filePath, (err) => {
    if (err && err.code !== "ENOENT") {
      console.error("==> Error deleting file: " + filePath, err);
    }
  });
}

// Make sure we don't have a pre-existing file
removeFile(output_file);

(async () => {
  const browser = await chromium.launch({
    headless: true,
  });
  const context = await browser.newContext({
    storageState: "auth/cookies.json",
  });
  const page = await context.newPage();
  console.log("\n==> Processing", series_URL);

  try {
    await page.goto(series_URL, { timeout: 30000 });
    await page.waitForTimeout(10000); // Wait for 10 seconds

    // 1) Get the top level page
    const mainPage = await page.locator("#maincontent").ariaSnapshot();
    writeEssentialData("Main page", mainPage, "  - tablist:", 0);

    // 2) Get the Genre from the About tab, which should always exist
    if (await elementExists(page, "tab", "About")) {
      await page.getByRole("tab", { name: "About" }).click();
      const aboutTab = await page
        .getByRole("tabpanel", { name: "About" })
        .ariaSnapshot();
      writeEssentialData("About tab", aboutTab, "    - listitem:", 2);
    } else {
      console.error('==> The "About" tab does not exist in', series_URL);
    }

    // 3) Get episodes from the Clips & Previews tab
    await handleTab(page, "Clips & Previews");

    // 4) Get episodes from the Special tab
    await handleTab(page, "Special");

    // 5) Get episodes from the Episodes tab
    await handleTab(page, "Episodes");
  } catch (error) {
    if (error.name === "TimeoutError") {
      console.error("==> Page load timed out for", series_URL);
    } else {
      console.error("==> Error during page navigation:", error.message);
    }
  } finally {
    await context.close();
    await browser.close();
  }
})();

process.on("unhandledRejection", (reason, promise) => {
  console.error("==> Unhandled Rejection at:", promise, "reason:", reason);
  process.exit(1);
});
