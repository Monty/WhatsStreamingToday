/* eslint capitalized-comments: "off", no-magic-numbers: "off"
    --------
    Magic numbers are time conversions, retry delays and parseInt radixes
  */
// getOPB-api.js -- build OPB RAW_DATA straight from pbs.org's own JSON endpoints.
//
// Replaces the per-show Playwright loop (getOPB-raw_data.js + rg + getOPB-raw_data.awk).
// Output is the same "showURL: / tabName: / episodeTitle: ... --EOE-- --EOS--" text
// that getOPB-raw_data.awk produced, so processOPB-raw_data.awk is unchanged.
//
// Data sources (the same ones the show page itself uses):
//   https://www.pbs.org/show/<slug>/                       one HTML fetch per show:
//        JSON-LD TVSeries  -> title, description, genre
//        inline RSC data   -> season lists for the Episodes and Clips & Previews tabs
//   /api/show/<slug>/season/<cid>/episodes/                Episodes tab, one per season
//   /api/show/<slug>/season/<cid>/extras/                  Clips & Previews tab, one per season
//   /api/show/<slug>/specials/                             Special(s) tab
//
// Usage:  node getOPB-api.js SHOW_URLS_FILE > RAW_DATA
//         node getOPB-api.js --franchise https://www.pbs.org/franchise/<name>/ >> SHOW_URLS
// Env:    ERRORS        anomalies file to append to (default: stderr)
//         RETRIES_FILE  shows that failed get appended here (as the old script did)
//         CONCURRENCY   shows fetched in parallel (default 4)
//         SHOW_LIMIT    only process the first N shows (testing)
//         STATION, STATION_ID, COUNTRY_ID  localization cookies (default OPB/KOPB, US)
//
// Changing the station:
//   pbs.org localizes episode lists by PBS station; without a station the episodes
//   endpoint returns []. These are plain values (no login, no expiration). To use a
//   different station, get its call sign and ID from either:
//     - pbs.org: pick the station, then browser dev tools -> Application -> Cookies
//       -> www.pbs.org -> pbsol.station and pbsol.station_id
//     - curl -s https://www.pbs.org/api/localize/   (guesses from your IP address)
//   then run, e.g.:  STATION=KQED STATION_ID=<stationId> ./makeOPB.sh -td
//   Episode lists can differ slightly between stations.

"use strict";
const fs = require("fs");

const BASE = "https://www.pbs.org";
const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";
// Episode lists are localized: without a station the episodes endpoint returns [].
// Defaults are OPB (KOPB); override with STATION / STATION_ID / COUNTRY_ID.
const STATION = process.env.STATION || "KOPB";
const STATION_ID =
  process.env.STATION_ID || "908d1940-5074-4a1e-b111-169206513fef";
const COUNTRY_ID = process.env.COUNTRY_ID || "US";
const COOKIE = `pbsol.station=${STATION}; pbsol.station_id=${STATION_ID}; pbsol.country_id=${COUNTRY_ID}`;
const CONCURRENCY = parseInt(process.env.CONCURRENCY, 10) || 4;
const SHOW_LIMIT = parseInt(process.env.SHOW_LIMIT, 10) || Infinity;
const MAX_TRIES = 4;

function usage() {
  console.error("Usage: node getOPB-api.js SHOW_URLS_FILE > RAW_DATA");
  console.error(
    "       node getOPB-api.js --franchise https://www.pbs.org/franchise/<name>/ >> SHOW_URLS",
  );
  console.error(
    "  SHOW_URLS_FILE: tab-separated lines of  url<TAB>title[<TAB>...]",
  );
  console.error(
    "  Env: ERRORS, RETRIES_FILE, CONCURRENCY (default 4), SHOW_LIMIT,",
  );
  console.error("       STATION, STATION_ID, COUNTRY_ID (default KOPB, US)");
  process.exit(1);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function get(url, kind) {
  let lastErr;
  for (let attempt = 1; attempt <= MAX_TRIES; attempt++) {
    try {
      const res = await fetch(url, {
        headers: {
          "User-Agent": UA,
          Cookie: COOKIE,
          Accept: kind === "json" ? "application/json" : "text/html",
        },
      });
      if (res.ok) {
        return kind === "json" ? await res.json() : await res.text();
      }
      lastErr = new Error(`HTTP ${res.status} for ${url}`);
      if (res.status === 404) {
        break;
      } // No point retrying
    } catch (err) {
      lastErr = err;
    }
    await sleep(1000 * attempt * attempt);
  }
  throw lastErr;
}

// ---- Page parsing -------------------------------------------------------

function decodeRSC(html) {
  const re = /self\.__next_f\.push\(\[1,("(?:[^"\\]|\\.)*")\]\)/g;
  let out = "";
  for (const m of html.matchAll(re)) {
    out += JSON.parse(m[1]);
  }
  return out;
}

function tvSeries(html) {
  const re = /<script type="application\/ld\+json"[^>]*>(.*?)<\/script>/gs;
  for (const m of html.matchAll(re)) {
    try {
      const j = JSON.parse(m[1]);
      for (const o of Array.isArray(j) ? j : [j]) {
        if (o && o["@type"] === "TVSeries") {
          return o;
        }
      }
    } catch {
      /* Ignore malformed blocks */
    }
  }
  return null;
}

// Parse the JSON array that starts at rsc[start] ('[')
function arrayAt(rsc, start) {
  let depth = 0;
  let inStr = false;
  for (let i = start; i < rsc.length; i++) {
    const c = rsc[i];
    if (inStr) {
      if (c === "\\") {
        i++;
      } else if (c === '"') {
        inStr = false;
      }
    } else if (c === '"') {
      inStr = true;
    } else if (c === "[" || c === "{") {
      depth++;
    } else if (c === "]" || c === "}") {
      if (--depth === 0) {
        return JSON.parse(rsc.slice(start, i + 1));
      }
    }
  }
  return null;
}

// The SeasonNavigator props block identified by a marker that follows it,
// e.g. "EpisodesTab.tsx" or '"contentType":"extras"'
function seasonsBefore(rsc, marker) {
  const at = rsc.indexOf(marker);
  if (at < 0) {
    return null;
  }
  const s = rsc.lastIndexOf('"seasons":[', at);
  if (s < 0) {
    return null;
  }
  return arrayAt(rsc, s + '"seasons":'.length);
}

function seasonLists(rsc) {
  const episodes =
    seasonsBefore(rsc, '"data-sentry-source-file":"EpisodesTab.tsx"') || [];
  let clips = seasonsBefore(rsc, '"contentType":"extras"') || [];
  // Clips entries may be references into the Episodes list:
  //   "$4b:props:tabs:0:content:0:props:children:0:props:seasons:4"
  clips = clips
    .map((c) => {
      if (typeof c !== "string") {
        return c;
      }
      const m = c.match(/:seasons:(\d+)$/);
      return m ? episodes[parseInt(m[1], 10)] : null;
    })
    .filter(Boolean);
  const tabs = [
    ...rsc.matchAll(/\{"title":"([^"]+)","slug":"([^"]+)","content"/g),
  ].map((m) => m[1]);
  return { episodes, clips, tabs };
}

// The old scraper read rendered text, where the browser collapses runs of
// whitespace (including embedded \r\n and tabs) and drops zero-width spaces.
// The API returns the raw strings, so normalize them the same way.
function clean(s) {
  return String(s ?? "")
    .replace(/[\u200B-\u200D\uFEFF]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

// ---- Episode description, as the page renders it ------------------------

function fmtDuration(sec) {
  sec = Math.floor(Number(sec) || 0);
  if (!sec) {
    return "";
  }
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  return [h && `${h}h`, m && `${m}m`, s && `${s}s`].filter(Boolean).join(" ");
}

function summary(v) {
  const p = v.parent || {};
  const ptype = p.resource_type;
  const vtype = v.video_type;
  const show = (p.season && p.season.show) || p.show || {};
  const displayEp = show.display_episode_number !== false;
  const prefix = ["preview", "clip"].includes(vtype)
    ? vtype[0].toUpperCase() + vtype.slice(1)
    : null;
  let h = null;
  if (ptype === "season") {
    h = `S${p.ordinal}`;
  } else if (ptype === "special") {
    h = "Special";
  } else if (ptype === "episode") {
    const season = p.season ? p.season.ordinal : "";
    if (displayEp) {
      h =
        show.seasons_count === 1
          ? `Ep${p.ordinal}`
          : `S${season || ""} Ep${p.ordinal}`;
    } else if (v.premiere_date) {
      const d = v.premiere_date.slice(0, 10).split("-").map(Number);
      h = `${d[1]}/${d[2]}/${d[0]}`;
    }
  }
  return { text: [prefix, h].filter(Boolean).join(": "), displayEp };
}

function description(v) {
  const { text, displayEp } = summary(v);
  let d = clean(v.description_short);
  if (text && displayEp) {
    d = `${text} | ${d}`;
  }
  const dur = fmtDuration(v.duration);
  if (dur) {
    d += ` (${dur})`;
  }
  return d;
}

// The Special(s) tab shows plain "description (duration)" with no summary prefix
function plainDescription(v) {
  const dur = fmtDuration(v.duration);
  return clean(v.description_short) + (dur ? ` (${dur})` : "");
}

function episodeLines(videos, plain = false) {
  const out = [];
  for (const v of videos) {
    out.push(`episodeTitle: ${clean(v.title)}`);
    out.push(`episodeURL: /video/${v.slug}/`);
    out.push(
      `episodeDescription: ${plain ? plainDescription(v) : description(v)}`,
    );
    out.push("--EOE--");
  }
  return out;
}

function header(tab, count, name) {
  return [
    `tabName: ${tab}`,
    `numberOfSeasons: ${count}`,
    `seasonName: ${name}`,
  ];
}

// ---- One show -----------------------------------------------------------

async function scrapeShow(showURL, anomalies) {
  const slug = showURL.replace(/\/$/, "").split("/").pop();
  const shortURL = showURL.replace(/.*pbs\.org/, "pbs.org");
  const html = await get(showURL, "text");
  const raw = tvSeries(html) || {};
  const ld = {
    name: clean(raw.name),
    description: clean(raw.description),
    genre: clean(raw.genre),
  };
  const rsc = decodeRSC(html);
  const { episodes, clips, tabs } = seasonLists(rsc);
  const api = (path) => get(`${BASE}/api/show/${slug}/${path}`, "json");

  const out = ["==> New File"];
  out.push(...header("Main", 1, "Season 1"), `showURL: ${showURL}`);
  const title = ld.name || "";
  if (title) {
    out.push(`showTitle: ${title}`);
  }
  if (ld.description) {
    out.push(`showDescription: ${ld.description}`);
  }
  out.push(...header("About", 1, "Season 1"));
  if (ld.genre) {
    out.push(`showGenre: ${ld.genre}`);
  }

  // A tab with one season has no season picker; the old scraper then
  // labelled it "Season 1" of 1 regardless of the real season number.
  async function seasonTab(tab, seasons, kind) {
    const lists = await Promise.all(
      seasons.map((s) => api(`season/${s.cid}/${kind}/`)),
    );
    if (kind === "episodes" && lists.every((l) => l.length === 0)) {
      throw new Error(
        `every Episodes season is empty (station cookie problem?)`,
      );
    }
    seasons.forEach((s, i) => {
      if (seasons.length > 1) {
        const name =
          s.ordinal === 0 ? "More Clips & Previews" : `Season ${s.ordinal}`;
        out.push(...header(tab, seasons.length, name));
      } else {
        out.push(...header(tab, 1, "Season 1"));
      }
      if (lists[i].length === 0) {
        anomalies.push(
          `==> 0 ${kind} in ${tab} season ${s.ordinal}: ${shortURL} '${title}'`,
        );
      }
      out.push(...episodeLines(lists[i]));
    });
  }

  if (clips.length) {
    await seasonTab("Clips", clips, "extras");
  }

  if (tabs.some((t) => /^Specials?$/.test(t))) {
    const specials = await api("specials/");
    if (specials.length) {
      out.push(...header("Special", 1, "Season 1"));
      out.push(...episodeLines(specials, true));
    }
  }

  if (episodes.length) {
    await seasonTab("Episodes", episodes, "episodes");
  } else if (!/There are no episodes currently available/.test(rsc)) {
    anomalies.push(`==> No Episodes tab: ${shortURL} '${title}'`);
  }

  out.push("--EOS--", "");

  // Same checks getOPB-raw_data.awk made
  if (!title) {
    anomalies.push(`==> No show title found: ${shortURL}`);
  }
  if (!ld.description) {
    anomalies.push(`==> No show descriptions found: ${shortURL} '${title}'`);
  }
  if (!ld.genre) {
    anomalies.push(`==> No show genre found: ${shortURL} '${title}'`);
  }
  return out.join("\n") + "\n";
}

// ---- Franchise pages (replaces getOPB-FranchiseURLs.js) -----------------

function decodeEntities(s) {
  const named = {
    amp: "&",
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
    nbsp: "\u00a0",
  };
  return s.replace(/&(#x[0-9a-f]+|#\d+|\w+);/gi, (m, e) => {
    if (e[0] === "#") {
      const n =
        e[1].toLowerCase() === "x"
          ? parseInt(e.slice(2), 16)
          : parseInt(e.slice(1), 10);
      return String.fromCodePoint(n);
    }
    return named[e.toLowerCase()] ?? m;
  });
}

// Print url<TAB>name<TAB>clean_name for every show poster on a franchise page,
// in the same order and format getOPB-FranchiseURLs.js produced.
async function franchise(browseURL) {
  const html = await get(browseURL, "text");
  const re =
    /<a\b[^>]*class="[^"]*show_poster__link[^"]*"[^>]*>([\s\S]*?)<\/a>/g;
  const shows = new Map();
  for (const m of html.matchAll(re)) {
    const href = (m[0].match(/href="([^"]+)"/) || [])[1];
    const alt = (m[1].match(/<img\b[^>]*alt="([^"]*)"/) || [])[1];
    if (!href || !alt) {
      continue;
    }
    const url = href.startsWith("http")
      ? href
      : `${BASE}${decodeEntities(href)}`;
    const name = decodeEntities(alt).trim();
    if (name && !shows.has(url)) {
      shows.set(url, name);
    }
  }
  const rows = [...shows]
    .sort((a, b) => a[1].localeCompare(b[1], "en", { sensitivity: "base" }))
    .map(([url, name]) => {
      const clean = name.replace(/[^a-zA-Z0-9 ]/g, "").replace(/ /g, "_");
      return `${url}\t${name}\t${clean}`;
    });
  if (rows.length === 0) {
    throw new Error(`No show posters found on ${browseURL}`);
  }
  process.stdout.write(rows.join("\n") + "\n");
  console.error(`==> Found ${rows.length} shows on ${browseURL}`);
}

// ---- Main ---------------------------------------------------------------

async function main() {
  if (process.argv[2] === "--franchise") {
    if (!process.argv[3]) {
      usage();
    }
    try {
      await franchise(process.argv[3]);
    } catch (err) {
      console.error(`==> \x1b[31mError\x1b[0m ${err.message}`);
      process.exit(1);
    }
    return;
  }
  const file = process.argv[2];
  if (!file || !fs.existsSync(file)) {
    usage();
  }
  const shows = fs
    .readFileSync(file, "utf8")
    .split("\n")
    .filter((l) => l.trim())
    .map((l) => l.split("\t")[0])
    .slice(0, SHOW_LIMIT);

  const results = new Array(shows.length);
  const anomalies = [];
  const failed = [];
  let next = 0;
  async function worker() {
    while (next < shows.length) {
      const i = next++;
      try {
        results[i] = await scrapeShow(shows[i], anomalies);
        console.error(`==> Completed ${shows[i]}`);
      } catch (err) {
        failed.push(shows[i]);
        anomalies.push(
          `==> getOPB-api.js failed on ${shows[i]}: ${err.message}`,
        );
        console.error(`==> \x1b[31mError\x1b[0m ${shows[i]}: ${err.message}`);
      }
    }
  }
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));

  process.stdout.write(results.filter(Boolean).join(""));
  if (anomalies.length) {
    const text = anomalies.join("\n") + "\n";
    if (process.env.ERRORS) {
      fs.appendFileSync(process.env.ERRORS, text);
    } else {
      process.stderr.write(text);
    }
  }
  if (failed.length && process.env.RETRIES_FILE) {
    fs.appendFileSync(process.env.RETRIES_FILE, failed.join("\n") + "\n");
  }
}

if (require.main === module) {
  main();
}
module.exports = { scrapeShow };
