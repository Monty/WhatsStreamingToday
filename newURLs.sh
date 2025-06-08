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

# Default to using the second oldest release
BACK="${BACK:-2}"
if [[ $BACK -lt 2 ]]; then
    BACK=2
fi

# shellcheck disable=SC1091 # waitUntil.function is a local file
source waitUntil.function

#    Acorn-columns/episode_urls-250603.txt
#    - Acorn-columns/show_urls-250603.txt
ACORN_URLS=$(find Acorn-columns/episode_urls-*.txt | tail -1)
ACORN_URLS_OLD=$(find Acorn-columns/episode_urls-*.txt | tail -"$BACK" | head -1)
#
#    BBox-columns/all_URLs-250603.txt
BBOX_URLS=$(find BBox-columns/all_URLs-*.txt | tail -1)
BBOX_URLS_OLD=$(find BBox-columns/all_URLs-*.txt | tail -"$BACK" | head -1)
#
#    MHz-columns/MHz_urls-250603.txt
#    - MHz-columns/episode_urls-250603.txt
#    - MHz-columns/movie_urls-250603.txt
#    - MHz-columns/season_urls-250603.txt
MHZ_URLS=$(find MHz-columns/MHz_urls-*.txt | tail -1)
MHZ_URLS_OLD=$(find MHz-columns/MHz_urls-*.txt | tail -"$BACK" | head -1)
#
#    OPB-columns/show_urls-250603.txt
#    - OPB-columns/raw_data-250603.txt
OPB_URLS=$(find OPB-columns/show_urls-*.txt | tail -1)
OPB_URLS_OLD=$(find OPB-columns/show_urls-*.txt | tail -"$BACK" | head -1)

printf "\n==> Show new URLs since $MHZ_URLS_OLD"
if waitUntil -Y "?"; then
    zet diff "$MHZ_URLS" "$MHZ_URLS_OLD" |
        sd "https://watch.mhzchoice.com/" "" |
        rg -v "^coming-soon/|-available-"
fi

printf "\n==> Show new URLs since $ACORN_URLS_OLD"
if waitUntil -Y "?"; then
    zet diff "$ACORN_URLS" "$ACORN_URLS_OLD" |
        sd "https://acorn.tv/" ""
fi

printf "\n==> Show new URLs since $OPB_URLS_OLD"
if waitUntil -Y "?"; then
    zet diff "$OPB_URLS" "$OPB_URLS_OLD" |
        sd "https://www.pbs.org/" ""
fi

printf "\n==> Show new URLs since $BBOX_URLS_OLD"
if waitUntil -Y "?"; then
    zet diff "$BBOX_URLS" "$BBOX_URLS_OLD" |
        sd "https://www.britbox.com/(us|ca)/" "" | rg "^episode/" |
        rg -v "Casualty_|Coming_Soon_|Coronation_Street_|Eastenders_" |
        rg -v "Emmerdale_|Gardeners_World_|Hetty_Wainthropp_|Taggart_"
fi
