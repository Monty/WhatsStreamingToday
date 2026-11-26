#!/usr/bin/env python3
"""Turn BritBox API JSON into the tv_movies/tv_shows/tv_episodes text files.

The output has the same "key: value" format that getBBox-preprocess.awk
produced from the HTML pages, so getBBoxMovies.awk, getBBoxShows.awk and
getBBoxEpisodes.awk work unchanged.

JSON files are the responses from
    https://api.britbox.com/v1/content/Page?path=/<type>/<name>&...
saved as <type>_<name>.json in JSON_DIR (see makeBBoxFromSitemap.sh).

Every season page carries its show's full record, so show pages are only
needed for shows with no season page. --missing-shows lists those.

Usage:
    getBBoxFromAPI.py [-e ERRORS] URL_LIST JSON_DIR MOVIES_TXT SHOWS_TXT EPISODES_TXT
    getBBoxFromAPI.py --missing-shows URL_LIST JSON_DIR
"""

import argparse
import json
import sys
from pathlib import Path

SITE = "https://www.britbox.com"


def esc(value):
    """Render a JSON string the way it looked after the HTML pipeline:
    still JSON-escaped, escaped double quotes turned into apostrophes
    (sd '\\"' '&#39;'), and literal \\t sequences dropped (awk gsub)."""
    text = json.dumps(str(value), ensure_ascii=False)[1:-1]
    return text.replace('\\"', "'").replace("\\t", "")


def num(value):
    """Numbers as JSON prints them (2015, not 2015.0)."""
    return json.dumps(value)


MISSING = object()  # no file: the download failed and was already logged


def load_item(path):
    """Return the page's main item, MISSING if there is no file,
    or None if the file is not usable API data."""
    if not path.exists():
        return MISSING
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return data["externalResponse"]["entries"][0]["item"]
    except (OSError, ValueError, KeyError, IndexError, TypeError):
        return None


def by_id_desc(items):
    """Order items the way `sort -ur` ordered their lines: by the id string,
    byte-wise, descending. The id is followed by a quote, which sorts below
    digits, so "9" comes before "10" just as it did."""
    return sorted(
        items, key=lambda it: (str(it.get("id", "")) + '"').encode(), reverse=True
    )


def single(values):
    """The genre rules only matched one-element arrays."""
    if isinstance(values, list) and len(values) == 1:
        return values[0]
    return None


def credit_lines(out, credits):
    for c in credits or []:
        out.append("person_role: " + esc(c.get("role", "")))
        out.append("person_name: " + esc(c.get("name", "")))
        out.append("person_URL: " + esc(c.get("path", "")))
        out.append("character_name: " + esc(c.get("character", "")))


def season_lines(out, seasons):
    for s in by_id_desc(seasons):
        out.append("itemType: season")
        out.append("seasonKey: " + esc(s["id"]))
        if s.get("title"):
            out.append("seasonFullTitle: " + esc(s["title"]))
        if s.get("contextualTitle"):
            out.append("seasonTitle: " + esc(s["contextualTitle"]))
        if s.get("showId"):
            out.append("episode_showId: " + esc(s["showId"]))
        rating = (s.get("classification") or {}).get("name")
        if rating:
            out.append("rating: " + esc(rating))
        if "releaseYear" in s:
            out.append("releaseYear: " + num(s["releaseYear"]))
        if "seasonNumber" in s:
            out.append("seasonNumber: " + num(s["seasonNumber"]))
        if s.get("customId"):
            out.append("customId: " + esc(s["customId"]))


def show_seasons_header(out, show_id, seasons_obj):
    """show_showId / numberOfSeasons / --EOS-- then the season list."""
    out.append("show_showId: " + esc(show_id))
    out.append("numberOfSeasons: " + num(seasons_obj.get("size", 0)))
    out.append("--EOS--")
    season_lines(out, seasons_obj.get("items", []))


def movie_block(url, item):
    out = [
        "--BOM--",
        "show_URL: " + url,
        "showTitle: " + item.get("title", ""),
        "showDescription: " + item.get("shortDescription", ""),
        "itemType: movie",
    ]
    genre = single(item.get("genres"))
    if genre:
        out.append("showGenre: " + esc(genre))
    credit_lines(out, item.get("credits"))
    # The HTML version took the first rating on the line, which was the
    # trailer's (usually NR). Use the movie's own rating.
    rating = (item.get("classification") or {}).get("name")
    if rating:
        out.append("rating: " + esc(rating))
    if "releaseYear" in item:
        out.append("releaseYear: " + num(item["releaseYear"]))
    if "duration" in item:
        out.append("duration: " + num(item["duration"]))
    if item.get("customId"):
        out.append("customId: " + esc(item["customId"]))
        out.append("--EOM--")
    return out


def show_block(url, item, warn):
    """item is a show record: from a season page (preferred, it includes the
    season list) or from the show page itself."""
    out = [
        "--BOS--",
        "show_URL: " + url,
        "showTitle: " + item.get("title", ""),
        "showDescription: " + item.get("shortDescription", ""),
        "itemType: show",
    ]
    genre = single(item.get("genres"))
    if genre:
        out.append("showGenre: " + esc(genre))
    credit_lines(out, item.get("credits"))
    seasons_obj = item.get("seasons")
    if seasons_obj:
        show_seasons_header(out, item["id"], seasons_obj)
    else:
        warn("==> No seasons found for " + url)
    return out


def season_block(url, item, warn):
    show = item.get("show") or {}
    out = [
        "--BOS--",
        "show_URL: " + url,
        "showTitle: " + show.get("title", ""),
        "showDescription: " + show.get("shortDescription", ""),
    ]
    season_lines(out, (show.get("seasons") or {}).get("items", []))

    episodes = item.get("episodes") or {}
    paging = episodes.get("paging") or {}
    if paging.get("total", 1) > 1:
        warn(f"==> Only page 1 of {paging['total']} of episodes in {url}")

    for e in by_id_desc(episodes.get("items", [])):
        out.append("--BOE--")
        out.append("itemType: episode")
        if e.get("title"):
            out.append("episodeFullTitle: " + esc(e["title"]))
        if e.get("contextualTitle"):
            out.append("episodeTitle: " + esc(e["contextualTitle"]))
        if e.get("showId"):
            out.append("episode_showId: " + esc(e["showId"]))
        if "episodeNumber" in e:
            out.append("episodeNumber: " + num(e["episodeNumber"]))
        if e.get("seasonId"):
            out.append("seasonId: " + esc(e["seasonId"]))
        if "shortDescription" in e:
            out.append("episodeDescription: " + esc(e["shortDescription"]))
        genre = single(e.get("genres"))
        if genre is not None:
            out.append("episodeGenre: " + esc(genre))
        rating = (e.get("classification") or {}).get("name")
        if rating:
            out.append("rating: " + esc(rating))
        if str(e.get("path", "")).startswith("/episode"):
            out.append("episode_URL: " + SITE + esc(e["path"]))
        if "releaseYear" in e:
            out.append("releaseYear: " + num(e["releaseYear"]))
        if e.get("episodeName"):
            out.append("episodeName: " + esc(e["episodeName"]))
        if "duration" in e:
            out.append("duration: " + num(e["duration"]))
        if e.get("customId"):
            out.append("customId: " + esc(e["customId"]))
            out.append("--EOE--")
    return out


def main():
    parser = argparse.ArgumentParser(
        description="Convert BritBox API JSON into tv_*.txt files."
    )
    parser.add_argument("-e", "--errors", help="anomalies file to append to")
    parser.add_argument(
        "--missing-shows",
        action="store_true",
        help="only list show URLs that no season page covers",
    )
    parser.add_argument("url_list", help="all_URLs file from the sitemap")
    parser.add_argument("json_dir", help="directory of <type>_<name>.json files")
    parser.add_argument("movies_txt", nargs="?")
    parser.add_argument("shows_txt", nargs="?")
    parser.add_argument("episodes_txt", nargs="?")
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()
    if not args.missing_shows and not (
        args.movies_txt and args.shows_txt and args.episodes_txt
    ):
        parser.error("MOVIES_TXT, SHOWS_TXT and EPISODES_TXT are required")

    messages = []

    def warn(msg):
        messages.append(msg)

    json_dir = Path(args.json_dir)
    urls = {"movie": [], "show": [], "season": []}
    for line in Path(args.url_list).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if "/us/" not in line:
            continue
        path = line.split("/us", 1)[1]  # /season/Grace_S1_10097327
        kind = path.split("/")[1]
        if kind in urls:
            urls[kind].append((line, path))

    def item_for(path):
        return load_item(json_dir / (path.lstrip("/").replace("/", "_") + ".json"))

    # Load season pages first: each carries its show's record, keyed here by
    # the show's customId, the last _ field of its URL (Grace_65424 -> 65424).
    # Paths can't be compared: the API keeps characters the sitemap drops,
    # e.g. /show/Maigret_(1992)_p05t7c9c vs /show/Maigret_1992_p05t7c9c.
    # Single-season "_FS_" shows use their season's id in the show URL
    # (show/Bleak_House_FS_p045vgwj, season/Bleak_House_S1_p045vgwj), so
    # each show record is also indexed by its seasons' customIds.
    season_items = []
    shows_from_seasons = {}
    by_season_id = {}
    for url, path in urls["season"]:
        item = item_for(path)
        season_items.append((url, path, item))
        if isinstance(item, dict) and item.get("show"):
            show = item["show"]
            shows_from_seasons.setdefault(str(show.get("customId")), show)
            for s in (show.get("seasons") or {}).get("items", []):
                by_season_id.setdefault(str(s.get("customId")), show)
    for key, show in by_season_id.items():
        shows_from_seasons.setdefault(key, show)

    def show_key(path):
        return path.rsplit("_", 1)[-1]

    if args.missing_shows:
        for url, path in urls["show"]:
            if show_key(path) not in shows_from_seasons:
                print(url)
        return

    def show_item(path):
        return shows_from_seasons.get(show_key(path)) or item_for(path)

    def write(out_name, kind, entries, make_block):
        with open(out_name, "w", encoding="utf-8") as out:
            for url, path, item in entries:
                if item is MISSING:
                    continue
                if item is None:
                    warn("==> SKIPPED (unusable API data): " + url)
                    continue
                source = path.lstrip("/")
                lines = ["==> New File", "--BOF-- " + source]
                lines += make_block(url, item)
                lines += ["--EOF-- " + source, ""]
                out.write("\n".join(lines) + "\n")

    write(
        args.movies_txt,
        "movie",
        [(u, p, item_for(p)) for u, p in urls["movie"]],
        movie_block,
    )
    write(
        args.shows_txt,
        "show",
        [(u, p, show_item(p)) for u, p in urls["show"]],
        lambda u, it: show_block(u, it, warn),
    )
    write(
        args.episodes_txt,
        "season",
        season_items,
        lambda u, it: season_block(u, it, warn),
    )

    if messages:
        if args.errors:
            with open(args.errors, "a", encoding="utf-8") as err:
                err.write("\n".join(messages) + "\n")
        else:
            print("\n".join(messages), file=sys.stderr)


if __name__ == "__main__":
    main()
