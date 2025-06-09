#!/usr/bin/env bash
#
# diff the most recent URL files from MHz, Acorn, OPB, and Britbox
# and print the new URLs

# Possible target URL files
#    Acorn-columns/episode_urls-250603.txt
#    - Acorn-columns/show_urls-250603.txt
#    OPB-columns/show_urls-250603.txt
#    - OPB-columns/raw_data-250603.txt

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

while getopts ":b:" opt; do
    case $opt in
    b)
        BACK="$OPTARG"
        ;;
    :)
        printf "Option -$OPTARG requires a numeric argument specifying " >&2
        printf "the nth newest release to use.\n" >&2
        exit 1
        ;;
    *)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    esac
done

# Default to using the newest release
BACK="${BACK:-1}"

# shellcheck disable=SC1091 # waitUntil.function is a local file
source waitUntil.function

ACORN_SHOWS=Acorn-columns/new_show_urls.txt
ACORN_SHOWS_OLD=$(find Acorn-columns/show_urls-*.txt | tail -"$BACK" | head -1)
ACORN_URLS=Acorn-columns/new_episode_urls.txt
ACORN_URLS_OLD=$(find Acorn-columns/episode_urls-*.txt | tail -"$BACK" | head -1)
#
BBOX_URLS=BBox-columns/new_episode_urls.txt
BBOX_URLS_OLD=$(find BBox-columns/all_URLs-*.txt | tail -"$BACK" | head -1)
#
MHZ_URLS=MHz-columns/new_episode_urls.txt
MHZ_URLS_OLD=$(find MHz-columns/MHz_urls-*.txt | tail -"$BACK" | head -1)
#
OPB_URLS=OPB-columns/new_episode_urls.txt
OPB_URLS_OLD=$(find OPB-columns/show_urls-*.txt | tail -"$BACK" | head -1)

printf "\n==> Show new URLs since $MHZ_URLS_OLD"
if waitUntil -Y "?"; then
    rm -f "$MHZ_URLS"
    SITEMAP_URL="https://watch.mhzchoice.com/sitemap.xml"
    printf "==> Downloading new $MHZ_URLS\n"
    curl -s $SITEMAP_URL |
        rg '<loc>https://watch.mhzchoice.com/..*</loc>' |
        sed -e 's+^[ \t]*<loc>++;s+</loc>++' -e 's+%2F+/+' |
        rg -v 'dubbed/|hjerson-english/|-dubbed-collection/' |
        rg -v '/all-series/videos/|/drama-crime/videos/' |
        sort -f >"$MHZ_URLS"
    zet diff "$MHZ_URLS" "$MHZ_URLS_OLD" |
        sd "https://watch.mhzchoice.com/" "" |
        rg -v "^coming-soon/|-available-|/videos/pr-" |
        rg -v "/season:[0-9]{1,2}$"
fi

printf "\n==> Show new URLs since $ACORN_SHOWS_OLD"
if waitUntil -Y "?"; then
    rm -f "$ACORN_SHOWS" "$ACORN_URLS"
    SITEMAP_URL="https://acorn.tv/browse/all"
    printf "==> Downloading new $ACORN_SHOWS\n"
    curl -s $SITEMAP_URL | grep '<a itemprop="url"' |
        sed -e 's+.*http+http+' -e 's+/">$++' |
        sort -f >"$ACORN_SHOWS"
    zet diff "$ACORN_SHOWS" "$ACORN_SHOWS_OLD" |
        sd "https://acorn.tv/" ""
fi

printf "\n==> Show new URLs since $OPB_URLS_OLD"
if waitUntil -Y "?"; then
    rm -f "$OPB_URLS"
    zet diff "$OPB_URLS" "$OPB_URLS_OLD" |
        sd "https://www.pbs.org/" ""
fi

printf "\n==> Show new URLs since $BBOX_URLS_OLD"
if waitUntil -Y "?"; then
    rm -f "$BBOX_URLS"
    SITEMAP_URL="https://www.britbox.com/dynamic-sitemap.xml"
    printf "==> Downloading new $BBOX_URLS\n"
    curl -s $SITEMAP_URL | rg en-us |
        awk -f getBBoxURLsFromSitemap.awk |
        sd /ca/ /us/ | sort -fu >"$BBOX_URLS"
    zet diff "$BBOX_URLS" "$BBOX_URLS_OLD" |
        rg -v "/us/season/|/us/show/" |
        sd "https://www.britbox.com/us/(episode/|movie/)" "" |
        rg -v "Casualty_|Coming_Soon_|Coronation_Street_|Eastenders_" |
        rg -v "Emmerdale_|Gardeners_World_|Prime_Ministers_Questions_" |
        rg -v "The_Inspector_Lynley_Mysteries_" | sort -f
fi
