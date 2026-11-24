#!/usr/bin/env python3
"""Produce raw MHz Choice spreadsheet rows using the VHX v2 API.

Replaces getMHzFromSitemap.awk (season pages) and getMHzCast.awk (episode
pages) after MHz moved to a client-rendered site. For each show URL it:

  1. fetches the show page once and reads the embedded data-props JSON
     (API base, site id, public token, collection id, season ids) plus the
     <title> and <meta name="description"> header,
  2. pages through each season's items via the API,
  3. prints show, season and episode rows (same tab-separated layout the old
     awk produced) on stdout, appends titles to RAW_TITLES and cast/crew to
     RAW_CREDITS, and logs anomalies to ERRORS.

Show URLs are read from the command line, or from stdin if none are given.
"""

import argparse
import html
import json
import re
import sys
import time
import urllib.error
import urllib.request

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
PER_PAGE = 24  # what the MHz front end uses

# Show_Type column in RAW_CREDITS (getMHzCast.awk always used tv_show)
SHOW_TYPE_SERIES = "tv_show"
SHOW_TYPE_MOVIE = "tv_show"


class Ctx:
    def __init__(self, errors, raw_titles, raw_credits):
        self.errors = errors
        self.raw_titles = raw_titles
        self.raw_credits = raw_credits

    def err(self, msg):
        self.errors.write(msg + "\n")
        self.errors.flush()


# ---------------------------------------------------------------- fetching


def fetch(url, token=None, tries=3):
    """Return (status, body_text). status 0 means a network error."""
    headers = {"User-Agent": UA}
    if token:
        headers["Authorization"] = "Bearer " + token
        headers["Accept"] = "application/json"
    req = urllib.request.Request(url, headers=headers)
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.status, r.read().decode("utf-8", "replace")
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503, 504) and attempt < tries - 1:
                time.sleep(2 * (attempt + 1))
                continue
            return e.code, ""
        except (urllib.error.URLError, TimeoutError, ConnectionError):
            if attempt < tries - 1:
                time.sleep(2 * (attempt + 1))
                continue
            return 0, ""
    return 0, ""


# ----------------------------------------------------------- page parsing


def unescape_all(s):
    """Unescape repeatedly to handle double-escaped text like &amp;amp;."""
    prev = None
    while prev != s:
        prev, s = s, html.unescape(s)
    return s


def page_title(page):
    m = re.search(r"<title>(.*?)</title>", page, re.S)
    if not m:
        return ""
    t = unescape_all(m.group(1)).strip()
    t = re.sub(r" - MHz Choice$", "", t)
    return t.replace('\\"', '"')


def page_props(page):
    m = re.search(r'data-props="([^"]*)"', page)
    if not m:
        return None
    try:
        return json.loads(html.unescape(m.group(1)))
    except json.JSONDecodeError:
        return None


def page_description(page):
    m = re.search(r'<meta name="description" content="(.*?)">', page, re.S)
    return unescape_all(m.group(1)) if m else None


HEADER_FIXES = [
    # Special cases
    (r"SCANDINAVIAN CRIME FICTION \|", ""),  # Beck, Maria Wern, Wallander
    (r"\| ENGLISH \| UNITED STATES \|", "| UNITED STATES | ENGLISH |"),
    (r"WITH ENGLISH CAPTIONS", ""),  # Maigret: The Classic BBC Series
    (r"CRIME I ARGENTINA", "CRIME | ARGENTINA"),  # Mercy on Us
    (r"DRAMA \| CRIME ", "DRAMA - CRIME"),  # Petra
    (r"\| SWEDISH \| SWEDISH", "| SWEDEN | SWEDISH"),  # The Fighter
    # Typos
    (r"ENGLIGH", "ENGLISH"),
    (r"ENGISH", "ENGLISH"),
    (r"EGLISH", "ENGLISH"),
    (r"IN ENGLISH", "ENGLISH"),
    (r"IN GERMAN", "GERMAN"),
    (r"FRANCE WITH", "FRENCH WITH"),
    (r"IRISH GAELIC", "IRISH"),
    (r"GERMANY WITH", "GERMAN WITH"),
    (r"SERBIAN \(CYRILLIC\)", "SERBIAN"),
    (r"WITH ENGLISH SUBTITLES", ""),
    (r"[Ww]ith [Ee]nglish [Ss]ubtitles", ""),
    (r"NON-*FICTION *[-–] *DOCUMENTARY", "Documentary"),
]


def parse_header(header_line):
    """Return genre, country, language, rating from the description header."""
    h = header_line
    for pat, rep in HEADER_FIXES:
        h = re.sub(pat, rep, h, count=1)
    h = re.sub(r" *\| *", "|", h).replace("\r", "").lstrip(" ")
    fld = h.split("|")
    while len(fld) < 4:
        fld.append("")
    for i in range(3):
        f = fld[i][:1] + fld[i][1:].lower()
        sp = f.find(" ")
        if sp >= 0:
            f = f[: sp + 1] + f[sp + 1 : sp + 2].upper() + f[sp + 2 :]
        fld[i] = f
    fld[0] = fld[0].replace("Drama-crime", "Drama - crime", 1)
    fld[3] = fld[3].replace(" ", "")
    return fld[0], fld[1], fld[2], fld[3]


def show_descriptor(desc, show_title, ctx):
    """Build 'genre\\tcountry\\tlanguage\\trating\\tdescription'."""
    if desc is None:
        ctx.err(f'==> No description meta for "{show_title}"')
        return "\t\t\t\t"
    lines = desc.replace("\r", "").split("\n")
    header = None
    if len(lines[0].split("|")) >= 4:
        header = lines.pop(0)
        if (
            not re.search(r"\| +TV *-", header)
            and lines
            and re.search(r" *TV *-", lines[0])
        ):
            header = header + " " + lines.pop(0)
    if len(lines) > 1:
        ctx.err(f'==> Multi line description in "{show_title}"')
    body = re.sub(r"  +", " ", " ".join(lines)).strip().replace('\\"', '"')
    if header is None:
        ctx.err(f'==> Added blank header for "{show_title}"')
        return "\t\t\t\t" + body
    return "\t".join(parse_header(header)) + "\t" + body


# ------------------------------------------------------------- show fixes


def fix_show_title(title, show_url, ctx):
    renames = {
        "awake-1": "Awake (Serbia)",
        "awake": "Awake (Lebanon)",
        "the-silence-1": "The Silence (Germany)",
        "the-silence": "The Silence (Croatia)",
    }
    slug = show_url.rstrip("/").rsplit("/", 1)[-1]
    if slug in renames:
        new = renames[slug]
        ctx.err(f'==> Changed {title} to "{new}"')
        return new
    return title


SNEP_ANY = re.compile(r"[Ss][Nnm]*[ ]*\d+[ ]+[Ee][Pp]*[ ]*\d+\s*\)")
SNEP_GOOD = re.compile(r" \(Sn \d+ Ep \d+\)")
SNEP_STRIP = re.compile(r"[ ]*\([ ]*[Ss][Nnm]*[ ]*\d+[ ]+[Ee][Pp]*[ ]*\d+\s*\)")


def clean_episode_title(title, show_title, ctx):
    t = unescape_all(title).strip().replace('\\"', '"')

    # Make Montalbano titles agree with MHz listing
    if re.match(r"^Montalbano|^Detective Montalbano:", t):
        t = t.replace("(Ep", "(Sn 1 Ep", 1)
        t = re.sub(r"^Montalbano:", "Detective Montalbano:", t)
        t = re.sub(r"^Montalbano and Me", "Detective Montalbano: Montalbano and Me", t)

    # Fix inconsistencies in "Murder In..."
    if show_title.startswith("Murder In"):
        t = re.sub(r"^Murder In(…: |… |\.\.: |\.\.\.: |\.\.\. |\.\.\.)", "", t)

    # Remove redundant show title prefix
    low, st = t.lower(), show_title.lower()
    if t.startswith("Vincenzo Malinconico-The Italian Lawyer: "):
        t = t[len("Vincenzo Malinconico-The Italian Lawyer: ") :]
    else:
        for sep in (": ", ":", "; ", " - "):
            if low.startswith(st + sep):
                t = t[len(st + sep) :]
                break

    return t


def tidy_snep(t, show_title, ctx):
    """Report and strip a trailing (Sn 1 Ep 1) style marker."""
    if SNEP_ANY.search(t):
        if not SNEP_GOOD.search(t):
            ctx.err(f'==> Malformed Sn/Ep in "{show_title}: {t}"')
        t = SNEP_STRIP.sub("", t, count=1)
    return t


def title_episode_number(title, ep_url):
    """Episode number from the title or a few known URLs, as the old awk did."""
    num = None
    # Upcoming episodes: "- EP 507 Available..." or "Ep 803 Available..."
    m = re.search(r"\b[Ee][Pp] (\d{3,4})\b", title)
    if m:
        num = int(m.group(1)[-2:])
    # Trailing (Sn 1 Ep 1), (Ep 1), etc.
    m = re.search(r"\(.*[Ee][Pp] *(\d+)\s*\)", title)
    if m:
        num = int(m.group(1))
    if "special-division-" in ep_url:
        m = re.search(r"-ep-(\d+)", ep_url)
        if m:
            num = int(m.group(1))
    for key, n in (
        ("inspector-labrea-deadly-dreams-in-montparnasse", 3),
        ("frozen-dead-episode-04-1", 4),
        ("the-promise-episode-06", 6),
        ("voiceless-episode-04", 4),
    ):
        if key in ep_url:
            num = n
    return num


def url_episode_number(ep_url, have_sn):
    """Episode number from -c-x0110 or -c-01031 style URLs."""
    if "maigrt-c-x0110" in ep_url:
        return 1
    m = re.search(r"-c-x\d{3,4}$", ep_url)
    if m:
        return int(m.group(0)[-2:])
    m = re.search(r"-c-\d{5}", ep_url)
    if m and not have_sn:
        return int(m.group(0)[-3:])
    return None


def clean_person(name):
    name = unescape_all(name or "").strip()
    return re.sub(r"\.$", "", name)


def hms(seconds):
    s = int(seconds)
    return f"{s // 3600:02d}:{s % 3600 // 60:02d}:{s % 60:02d}"


def hyperlink(url, label):
    return f'=HYPERLINK("{url}";"{label}")'


# ------------------------------------------------------------- API access


def season_items(api, site, coll_id, token, ctx, label):
    """Yield all video entities in a collection, following pagination."""
    page = 1
    while page <= 100:
        url = (
            f"{api}/v2/sites/{site}/collections/{coll_id}/items"
            f"?page={page}&per_page={PER_PAGE}&include_coming_soon=1"
        )
        status, body = fetch(url, token)
        # A season with exactly PER_PAGE items: the API rejects the next page
        if status in (400, 404) and page > 1:
            return
        if status != 200:
            ctx.err(f"==> API status {status} for {label} page {page}")
            return
        try:
            data = json.loads(body)
        except json.JSONDecodeError:
            ctx.err(f"==> Bad API JSON for {label} page {page}")
            return
        items = data.get("items") or []
        for it in sorted(items, key=lambda i: i.get("position", 0)):
            if it.get("entity_type", "video") == "video" and it.get("entity"):
                yield it["entity"]
        if len(items) < PER_PAGE:
            return
        page += 1


# ----------------------------------------------------------- show processing


def process_show(show_url, ctx, out):
    status, page = fetch(show_url)
    if status != 200:
        msg = f"==> HTTP status for {show_url} is {status}"
        ctx.err(msg)
        print(msg, file=sys.stderr)
        return

    props = page_props(page)
    coll = (props or {}).get("collection") or {}
    if not props or not coll.get("id"):
        ctx.err(f"==> No data-props collection in {show_url}")
        return

    ctype = coll.get("type", "")
    seasons = (coll.get("series") or {}).get("seasons") or []
    if ctype not in ("series", "movie") and not seasons:
        ctx.err(f"==> Skipped {ctype or 'unknown'} collection {show_url}")
        return

    try:
        api = props["apiV2"]["url"].rstrip("/")
        token = props["apiV2"]["token"]
        site = props["site"]["id"]
    except (KeyError, TypeError):
        ctx.err(f"==> Missing apiV2/site info in {show_url}")
        return

    show_title = fix_show_title(page_title(page), show_url, ctx)
    descriptor = show_descriptor(page_description(page), show_title, ctx)
    is_movie = not seasons
    show_type = SHOW_TYPE_MOVIE if is_movie else SHOW_TYPE_SERIES
    show_slug = show_url.rstrip("/").rsplit("/", 1)[-1]

    # A movie has no seasons: treat its own collection as season 1
    if is_movie:
        seasons = [{"id": coll["id"], "number": 1}]

    rows = []
    credits = set()
    found_duration = False

    for season in sorted(seasons, key=lambda s: s.get("number", 0)):
        snum = season.get("number") or 1
        season_url = f"{show_url}/season:{snum}"
        label = f"{show_title} season {snum}"
        ep_rows = []
        pr_count = 0
        counted = 0

        for ent in season_items(api, site, season["id"], token, ctx, label):
            ep_url = ent.get("page_url") or ""
            raw_title = ent.get("title") or ""
            title = clean_episode_title(raw_title, show_title, ctx)
            md = ent.get("metadata") or {}

            # Episode type
            etype = "M" if is_movie else "E"
            if "BONUS" in title and not show_title.startswith("Detective Montalbano"):
                etype = "X"
            if title.startswith("PR |"):
                etype = "T"
                pr_count += 1

            # Episode number, same priority as the old awk:
            #   -c-x URL number (not Montalbano), trailer count,
            #   API episode_number, then the number in the title
            api_num = (md.get("season") or {}).get("episode_number")
            sn_num = title_episode_number(title, ep_url)
            cx_num = url_episode_number(ep_url, have_sn=bool(sn_num) or etype == "T")
            title = tidy_snep(title, show_title, ctx)

            epnum = None
            if cx_num and not show_title.startswith("Detective Montalbano"):
                epnum = cx_num
            elif etype == "T":
                epnum = pr_count
            elif api_num:
                epnum = api_num
            elif sn_num:
                epnum = sn_num
            elif etype != "T":
                # Last resort: position within the season, as the old
                # season page's "Episode N" label gave it
                epnum = counted + 1
            if is_movie and not epnum:
                epnum = 1
            if "what-to-watch-after-baylon-berlin" in ep_url:
                epnum = 13
            if "swan-company-matteo-s-arrival" in ep_url:
                epnum = 1
            if not epnum:
                ctx.err(
                    f'==> Missing episodeNumber in "{show_title}: {title}" {ep_url}'
                )
                epnum = 0

            # Duration
            secs = (ent.get("duration") or {}).get("seconds") or 0
            if secs:
                found_duration = True
                dur = hms(secs)
            else:
                ctx.err(f'==> Bad episodeDuration in "{show_title}: {title}"')
                dur = ""

            # Description
            desc = unescape_all(
                ent.get("description") or ent.get("short_description") or ""
            )
            desc = re.sub(r"\s+", " ", desc).strip().replace('\\"', '"')
            if not desc:
                if etype == "T":
                    desc = title
                else:
                    ctx.err(f"==> No description: {ep_url}")
            desc = re.sub(r"^PR \| ", "", desc)

            if etype != "T":
                counted += 1

            label_title = title.replace('"', '""')
            link = hyperlink(
                ep_url,
                f"{show_title}, S{snum:02d}{etype}{int(epnum):02d}, {label_title}",
            )
            ep_rows.append(f"{link}\t\t\t{dur}\t\t\t\t\t{desc}")

            # Credits: Show_Title is the display title (matches baseline),
            # crew lines have 4 fields
            for c in md.get("cast") or []:
                actor = clean_person(c.get("actor"))
                if not actor:
                    continue
                char = unescape_all(c.get("character") or "").strip()
                m = re.search(r" and | & ", actor)
                if m:
                    first = clean_person(actor[: m.start()])
                    actor = actor[m.end() :]
                    credits.add(f"{first}\tactor\t{show_type}\t{show_title}\t{char}")
                if "Hendrik Toompere" in actor:
                    actor = "Hendrik Toompere Jr."
                credits.add(f"{actor}\tactor\t{show_type}\t{show_title}\t{char}")
            for c in md.get("crew") or []:
                name = clean_person(c.get("name"))
                role = (c.get("role") or "").strip().lower()
                if "Manetti Bros" in name:
                    name = "The Manetti Bros."
                if name and role:
                    credits.add(f"{name}\t{role}\t{show_type}\t{show_title}")

        if not ep_rows:
            ctx.err(f"==> No episodes found for {label}")
            continue

        season_desc = "" if snum == 1 else descriptor
        season_link = hyperlink(season_url, f"{show_title}, S{snum:02d}, Season {snum}")
        rows.append(f"{season_link}\t\t{counted}\t\t{season_desc}")
        rows.extend(ep_rows)

    # Mirror the old awk: no durations means not a usable show
    if not found_duration:
        print(f'==> No duration found for "{show_title}"', file=sys.stderr)
        ctx.err(f'==> No duration found for "{show_title}"')
        return

    show_link = hyperlink(show_url, show_title)
    out.write(f"{show_link}\t{len(seasons)}\t\t\t{descriptor}\n")
    for r in rows:
        out.write(r + "\n")
    out.flush()

    ctx.raw_titles.write(show_title + "\n")
    for c in sorted(credits):
        ctx.raw_credits.write(c + "\n")
    ctx.raw_titles.flush()
    ctx.raw_credits.flush()


# -------------------------------------------------------------------- main


def main():
    ap = argparse.ArgumentParser(
        description="Produce raw MHz Choice spreadsheet rows from the VHX API.",
        epilog="Example:\n  sed -E 's|/season:[0-9]+$||' season_urls.txt | sort -fu |\n"
        "    %(prog)s -e errs.txt -t titles.txt -c credits.txt >> unsorted.txt",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("-e", "--errors", required=True, help="anomalies file (appended)")
    ap.add_argument(
        "-t", "--raw-titles", required=True, help="show titles file (appended)"
    )
    ap.add_argument(
        "-c", "--raw-credits", required=True, help="credits file (appended)"
    )
    ap.add_argument("urls", nargs="*", help="show URLs (default: read from stdin)")

    if len(sys.argv) == 1:
        ap.print_help()
        sys.exit(1)
    args = ap.parse_args()

    if args.urls:
        urls = args.urls
    elif sys.stdin.isatty():
        ap.error("no show URLs given on the command line or stdin")
    else:
        urls = [u.strip() for u in sys.stdin if u.strip()]

    with (
        open(args.errors, "a") as e,
        open(args.raw_titles, "a") as t,
        open(args.raw_credits, "a") as c,
    ):
        ctx = Ctx(e, t, c)
        for url in urls:
            try:
                process_show(url, ctx, sys.stdout)
            except Exception as ex:  # keep going on one bad show
                ctx.err(f"==> Error processing {url}: {type(ex).__name__}: {ex}")


if __name__ == "__main__":
    main()
