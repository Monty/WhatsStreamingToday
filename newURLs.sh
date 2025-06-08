#!/usr/bin/env bash
#
# diff the most recent URL files from MHz, Acorn, OPB, and Britbox
# and print the new URLs

# Possible target URL files
#    Acorn-columns/episode_urls-250603.txt
#    - Acorn-columns/show_urls-250603.txt
#    BBox-columns/all_URLs-250603.txt
#    MHz-columns/MHz_urls-250603.txt
#    - MHz-columns/episode_urls-250603.txt
#    - MHz-columns/movie_urls-250603.txt
#    - MHz-columns/season_urls-250603.txt
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

#    Acorn-columns/episode_urls-250603.txt
ACORN_URLS=Acorn-columns/new_episode_urls.txt
ACORN_URLS_OLD=$(find Acorn-columns/episode_urls-*.txt | tail -"$BACK" | head -1)
#
#    BBox-columns/all_URLs-250603.txt
BBOX_URLS=BBox-columns/new_episode_urls.txt
BBOX_URLS_OLD=$(find BBox-columns/all_URLs-*.txt | tail -"$BACK" | head -1)
#
#    MHz-columns/MHz_urls-250603.txt
#    - MHz-columns/episode_urls-250603.txt
#    - MHz-columns/movie_urls-250603.txt
#    - MHz-columns/season_urls-250603.txt
MHZ_URLS=MHz-columns/new_episode_urls.txt
MHZ_URLS_OLD=$(find MHz-columns/MHz_urls-*.txt | tail -"$BACK" | head -1)
#
#    OPB-columns/show_urls-250603.txt
#    - OPB-columns/raw_data-250603.txt
OPB_URLS=OPB-columns/new_episode_urls.txt
OPB_URLS_OLD=$(find OPB-columns/show_urls-*.txt | tail -"$BACK" | head -1)

printf "\n==> Show new URLs since $MHZ_URLS_OLD"
if waitUntil -Y "?"; then
    rm -f "$MHZ_URLS"
    zet diff "$MHZ_URLS" "$MHZ_URLS_OLD" |
        sd "https://watch.mhzchoice.com/" "" |
        rg -v "^coming-soon/|-available-"
fi

printf "\n==> Show new URLs since $ACORN_URLS_OLD"
if waitUntil -Y "?"; then
    rm -f "$ACORN_URLS"
    zet diff "$ACORN_URLS" "$ACORN_URLS_OLD" |
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
    zet diff "$BBOX_URLS" "$BBOX_URLS_OLD" |
        sd "https://www.britbox.com/(us|ca)/" "" | rg "^episode/" |
        rg -v "Casualty_|Coming_Soon_|Coronation_Street_|Eastenders_" |
        rg -v "Emmerdale_|Gardeners_World_|Hetty_Wainthropp_|Taggart_"
fi
