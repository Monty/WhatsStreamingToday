#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on BritBox
#
# shellcheck disable=SC2317

# Prevent cascading or pipe failures
set -euo pipefail

# trap and locate errors that might arise from pipefail
trap 'printf "${ERROR} at or near line %s:\n\t%s\n" \
    "$LINENO" "$BASH_COMMAND" >&2' ERR

# trap ctrl-c and SIGTERM -- call cleanup and exit
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
#
function cleanup() {
    stty sane
    printf "\n"
}

ERROR="\e[0;31m[Error]\e[0m"

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

# Make sort consistent between Mac and Linux
export LC_COLLATE="C"

# Create some timestamps
DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-s" switch to only output a summary. Delete any created files except anomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
# Use "-H" switch to scrape the HTML pages instead of using the BritBox API
DEBUG="no"
SUMMARY="no"
PRINT_TOTALS="no"
USE_HTML="no"
while getopts ":dstH" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    H)
        USE_HTML="yes"
        ;;
    s)
        SUMMARY="yes"
        ;;
    t)
        PRINT_TOTALS="yes"
        ;;
    \?)
        printf "[Warning] Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    esac
done

# Make sure we can execute curl.
if ! command -v curl >/dev/null; then
    printf "${ERROR} Can't run curl. Install curl and rerun this script.\n"
    printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
    exit 1
fi

# Make sure network is up and BritBox site is reachable
SITEMAP_URL="https://www.britbox.com/dynamic-sitemap.xml"
if ! curl -o /dev/null -Is $SITEMAP_URL; then
    printf "${ERROR} $SITEMAP_URL isn't available, or your network is down.\n"
    printf "        Try accessing $SITEMAP_URL in your browser.\n"
    exit 1
fi

# Required subdirectories
COLS="BBox-columns"
BASELINE="BBox-baseline"
mkdir -p $COLS $BASELINE

# File names are used in saveTodaysBBoxFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results

# In the default case -- input, output, and baseline files have no date information.
#   but intermediate files have today's date $DATE_ID inserted before the file extension.
# Error and debugging files always have a LONGDATE of the execution time inserted.

# Error and debugging info (per run)
POSSIBLE_DIFFS="BBox_diffs$LONGDATE.txt"
ERRORS="BBox_anomalies$LONGDATE.txt"

# List of all URLs obtained from SITEMAP_URL
SHOW_URLS="$COLS/all_URLs$DATE_ID.txt"

# Final output spreadsheets
CREDITS="BBox_TV_Credits$DATE_ID.csv"
SHORT_SPREADSHEET="BBox_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET="BBox_TV_ShowsEpisodes$DATE_ID.csv"

# Intermediate but useful spreadsheet files
EPISODES_CSV="$COLS/BBoxEpisodes$DATE_ID.csv"
MOVIES_CSV="$COLS/BBoxMovies$DATE_ID.csv"
SHOWS_CSV="$COLS/BBoxShows$DATE_ID.csv"

# Data files segregated by item type
TV_EPISODE_TXT="$COLS/tv_episodes$DATE_ID.txt"
TV_MOVIE_TXT="$COLS/tv_movies$DATE_ID.txt"
TV_SHOW_TXT="$COLS/tv_shows$DATE_ID.txt"

# Temp files used in generating final output spreadsheets
TEMP_SPREADSHEET="$COLS/temp_spreadsheet$DATE_ID.csv"

# Intermediate working files
RAW_CREDITS="$COLS/rawCredits$DATE_ID.csv"
RAW_TITLES="$COLS/rawTitles$DATE_ID.txt"
UNIQUE_PERSONS="BBox_uniqPersons$DATE_ID.txt"
UNIQUE_CHARACTERS="BBox_uniqCharacters$DATE_ID.txt"
UNIQUE_TITLES="BBox_uniqTitles$DATE_ID.txt"
DURATION="$COLS/total_duration$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_CREDITS="$BASELINE/credits.txt"
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
PUBLISHED_UNIQUE_PERSONS="$BASELINE/uniqPersons.txt"
PUBLISHED_UNIQUE_CHARACTERS="$BASELINE/uniqCharacters.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
#
PUBLISHED_SHOW_URLS="$BASELINE/all_URLs.txt"

# Filename groups used for cleanup
ALL_WORKING="$RAW_CREDITS $RAW_TITLES $TEMP_SPREADSHEET"
#
ALL_TXT="$UNIQUE_PERSONS $UNIQUE_CHARACTERS $UNIQUE_TITLES $DURATION"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET $LONG_SPREADSHEET $CREDITS"
#
ALL_CSVS="$MOVIES_CSV $SHOWS_CSV $EPISODES_CSV"

# Cleanup any possible leftover files
# shellcheck disable=SC2086
rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS

# Make sure we have a file to hold errors
touch "$ERRORS"

# Number of simultaneous page downloads and preprocessing jobs.
# Override from the command line, e.g.  MAX_PARALLEL=4 ./makeBBoxFromSitemap.sh -td
MAX_PARALLEL="${MAX_PARALLEL:-8}"

# Scratch directory for downloaded pages, removed when the script exits
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/BBox.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

# Grab the sitemap file and extract the URLs for en-us items
# Unless we already have one from today
if [ ! -e "$SHOW_URLS" ]; then
    printf "==> Downloading new $SHOW_URLS\n"
    curl -s $SITEMAP_URL | rg en-us |
        awk -f getBBoxURLsFromSitemap.awk | sort -fu >"$SHOW_URLS"
else
    printf "==> Using existing $SHOW_URLS\n"
fi

# Extract fields from one downloaded page. Runs in parallel child shells.
#   INVOCATION: preprocessPage url html_file
function preprocessPage() {
    # shellcheck disable=SC2016
    rg -f rg_BBox_keep.rgx <"$2" | sd '&quot;' '"' |
        sd '"type":"(movie|episode|show|season)"' '\n"type":"$1"' |
        sd '"offers".*' '' | sd '"subtype":"",' '' | sd '\\"' '&#39;' |
        sd '"path":"",' '' | sd '^[[:space:]]+' '' |
        rg -v -f rg_BBox_skip.rgx | sort -ur |
        awk -v FILE="$1" -f getBBox-preprocess.awk
}
export -f preprocessPage

# Download every page matching a URL pattern in parallel, preprocess them in
# parallel, then append the results in URL order so output matches a serial run.
#   INVOCATION: winnowHTML url_pattern output_file
function winnowHTML() {
    printf "==> Generating new $2\n"
    local dir="$WORK_DIR/${2##*/}"
    mkdir -p "$dir"
    rg -N "$1" "$SHOW_URLS" >"$dir/urls.txt" || true

    # One request per page (the old separate status check doubled the requests)
    awk -v DIR="$dir" \
        '{ printf("url = \"%s\"\noutput = \"%s/%d.html\"\n", $0, DIR, NR) }' \
        "$dir/urls.txt" >"$dir/curl.cfg"
    if [ -s "$dir/urls.txt" ]; then
        curl -sS --parallel --parallel-max "$MAX_PARALLEL" \
            --retry 3 --retry-delay 2 \
            -w '%{http_code}\t%{filename_effective}\n' \
            -K "$dir/curl.cfg" >"$dir/codes.txt" || true
    fi
    touch "$dir/codes.txt"

    # Log failed pages; list the good ones as "url html_file txt_file" jobs
    awk -v DIR="$dir" -v ERRORS="$ERRORS" '
        FNR == NR {
            n = $2; sub(/.*\//, "", n); sub(/\.html$/, "", n)
            code[n] = $1
            next
        }
        {
            c = (FNR in code) ? code[FNR] : "000"
            if (c + 0 == 0 || c + 0 >= 400) {
                printf("==> SKIPPED (HTTP %s): %s\n", c, $0) >> ERRORS
                next
            }
            printf("%s %s/%d.html %s/%d.txt\n", $0, DIR, FNR, DIR, FNR)
        }' "$dir/codes.txt" "$dir/urls.txt" >"$dir/jobs.txt"

    # Concatenate in URL order, then move into place so an interrupted run
    # never leaves a partial file that a rerun would treat as "existing".
    # Always creates $2, even when no URLs match (the 102146 failure).
    : >"$dir/all.txt"
    if [ -s "$dir/jobs.txt" ]; then
        # shellcheck disable=SC2016
        xargs -P "$MAX_PARALLEL" -n 3 "$BASH" -c 'preprocessPage "$1" "$2" >"$3"' _ \
            <"$dir/jobs.txt"
        awk '{ print $3 }' "$dir/jobs.txt" | xargs cat >"$dir/all.txt"
    fi
    mv "$dir/all.txt" "$2"
}

# The JSON the BritBox pages load their data from
API_URL="https://api.britbox.com/v1/content/Page"
API_QUERY="useCustomId=true&listPageSize=100&maxListPrefetch=15&itemDetailExpand=all"
API_QUERY+="&textEntryFormat=html&device=web_browser&sub=&segments=us"

# Download the API JSON for a list of BritBox URLs, 8 at a time.
# Failed downloads are logged by URL and their files removed so they are skipped.
#   INVOCATION: fetchAPIPages url_list json_dir
function fetchAPIPages() {
    local list="$1" dir="$2"
    [ -s "$list" ] || return 0

    # /us/season/Grace_S1_10097327 -> season_Grace_S1_10097327.json
    awk -v DIR="$dir" -v API="$API_URL" -v Q="$API_QUERY" '{
        path = $0; sub(/^.*\/us\//, "/", path)
        name = substr(path, 2); gsub(/\//, "_", name)
        qpath = path; gsub(/\//, "%2F", qpath)
        printf("url = \"%s?path=%s&%s\"\noutput = \"%s/%s.json\"\n",
            API, qpath, Q, DIR, name)
    }' "$list" >"$list.cfg"
    # --retry without --retry-delay backs off 1, 2, 4, 8, 16 seconds and
    # honors Retry-After, in case the API rate-limits us (HTTP 429)
    curl -sS --parallel --parallel-max "$MAX_PARALLEL" --retry 5 \
        -w '%{http_code}\t%{filename_effective}\n' \
        -K "$list.cfg" >"$list.codes" || true

    awk -v ERRORS="$ERRORS" '
        FNR == NR {
            n = $2; sub(/.*\//, "", n); sub(/\.json$/, "", n)
            code[n] = $1
            next
        }
        {
            name = $0; sub(/^.*\/us\//, "", name); gsub(/\//, "_", name)
            c = (name in code) ? code[name] : "000"
            if (c + 0 == 0 || c + 0 >= 400) {
                printf("==> SKIPPED (HTTP %s): %s\n", c, $0) >> ERRORS
                print name ".json"
            }
        }' "$list.codes" "$list" >"$list.failed"
    while read -r f; do
        rm -f "$dir/$f"
    done <"$list.failed"
}

# Get API JSON for movies and seasons, plus any show that no season page
# covers (each season page carries its show's full record), then convert
# it into the same tv_*.txt files that winnowHTML produces.
function fetchFromAPI() {
    printf "==> Generating new $TV_MOVIE_TXT, $TV_SHOW_TXT,\n"
    printf "    and $TV_EPISODE_TXT from the BritBox API\n"
    local dir="$WORK_DIR/api"
    mkdir -p "$dir"

    rg -N '/us/(movie|season)/' "$SHOW_URLS" >"$WORK_DIR/api_urls.txt" || true
    fetchAPIPages "$WORK_DIR/api_urls.txt" "$dir"

    python3 getBBoxFromAPI.py --missing-shows "$SHOW_URLS" "$dir" \
        >"$WORK_DIR/api_shows.txt"
    fetchAPIPages "$WORK_DIR/api_shows.txt" "$dir"

    python3 getBBoxFromAPI.py -e "$ERRORS" "$SHOW_URLS" "$dir" \
        "$dir/movies.txt" "$dir/shows.txt" "$dir/episodes.txt"
    mv "$dir/movies.txt" "$TV_MOVIE_TXT"
    mv "$dir/shows.txt" "$TV_SHOW_TXT"
    mv "$dir/episodes.txt" "$TV_EPISODE_TXT"
    API_DONE="yes"
}

# Unless all three exist from today, get the movie, show, and season data
# from the API in one pass. With -H, winnowHTML scrapes each type below.
API_DONE="no"
if [ "$USE_HTML" != "yes" ] &&
    { [ ! -e "$TV_MOVIE_TXT" ] || [ ! -e "$TV_SHOW_TXT" ] ||
        [ ! -e "$TV_EPISODE_TXT" ]; }; then
    printf "### Possible anomalies from downloading API data\n" >>"$ERRORS"
    fetchFromAPI
    printf "\n" >>"$ERRORS"
fi

# Get data for movies from /movie/ URLs
# Unless we already have one from today
printf "### Possible anomalies from processing $TV_MOVIE_TXT\n" >>"$ERRORS"
if [ ! -e "$TV_MOVIE_TXT" ]; then
    winnowHTML "/movie/" "$TV_MOVIE_TXT"
elif [ "$API_DONE" != "yes" ]; then
    printf "==> Using existing $TV_MOVIE_TXT\n"
fi
# Generate movies spreadsheet
awk -v ERRORS="$ERRORS" -v RAW_TITLES="$RAW_TITLES" -v RAW_CREDITS="$RAW_CREDITS" \
    -f getBBoxMovies.awk "$TV_MOVIE_TXT" |
    sort -fu --key=4 --field-separator=\" >"$MOVIES_CSV"

# Get data for shows from /show/ URLs
# Unless we already have one from today
printf "\n### Possible anomalies from processing $TV_SHOW_TXT\n" >>"$ERRORS"
if [ ! -e "$TV_SHOW_TXT" ]; then
    winnowHTML "/show/" "$TV_SHOW_TXT"
elif [ "$API_DONE" != "yes" ]; then
    printf "==> Using existing $TV_SHOW_TXT\n"
fi
# Generate shows spreadsheet
awk -v ERRORS="$ERRORS" -v RAW_TITLES="$RAW_TITLES" -v RAW_CREDITS="$RAW_CREDITS" \
    -f getBBoxShows.awk "$TV_SHOW_TXT" |
    sort -fu --key=4 --field-separator=\" >"$SHOWS_CSV"

# Get data for episodes from /season/ URLs
# Unless we already have one from today
printf "\n### Possible anomalies from processing $TV_EPISODE_TXT\n" >>"$ERRORS"
if [ ! -e "$TV_EPISODE_TXT" ]; then
    winnowHTML "/season/" "$TV_EPISODE_TXT"
elif [ "$API_DONE" != "yes" ]; then
    printf "==> Using existing $TV_EPISODE_TXT\n"
fi
# Generate episodes spreadsheet
awk -v ERRORS="$ERRORS" -f getBBoxEpisodes.awk "$TV_EPISODE_TXT" |
    sort -fu --key=4 --field-separator=\" >"$EPISODES_CSV"

# Sort the titles produced by getBBox*.awk scripts
sort -fu "$RAW_TITLES" >"$UNIQUE_TITLES"
# rm -f $RAW_TITLES

# Field numbers returned by getBBox*.awk scripts
#     1 Title       2 Seasons     3 Episodes        4 Duration       5 Genre
#     6 Year        7 Rating      8 Description     9 Content_Type  10 Content_ID
#    11 Item_Type  12 Date_Type  13 Original_Date  14 Show_ID       15 Season_ID
#    16 Sn_#       17 Ep_#       16 1st_#          17 Last_#

titleCol="1"

# Pick columns to display
# NOTE: Content_Type is required for calculateBBoxShowDurations.awk
if [ "$DEBUG" != "yes" ]; then
    spreadsheet_columns="1-9"
else
    spreadsheet_columns="1-16"
fi

# Generate LONG_SPREADSHEET and SHORT_SPREADSHEET
# shellcheck disable=SC2086
touch $ALL_SPREADSHEETS $ALL_CSVS
# Make TEMP_SPREADSHEET containing ALL columns
head -1 "$MOVIES_CSV" >"$TEMP_SPREADSHEET"
# shellcheck disable=SC2086
rg -I '=HYPERLINK' $ALL_CSVS |
    sort -fu --key=4 --field-separator=\" >>"$TEMP_SPREADSHEET"
# Make LONG_SPREADSHEET containing selected columne
cut -f $spreadsheet_columns "$TEMP_SPREADSHEET" >"$LONG_SPREADSHEET"
# Make SHORT_SPREADSHEET by adding up durations from LONG_SPREADSHEET
tail -r "$LONG_SPREADSHEET" | awk -v ERRORS="$ERRORS" -v DURATION="$DURATION" \
    -f calculateBBoxShowDurations.awk | tail -r >"$SHORT_SPREADSHEET"
# Add number of episodes to LONG_SPREADSHEET
mv "$LONG_SPREADSHEET" "$TEMP_SPREADSHEET"
tail -r "$TEMP_SPREADSHEET" | awk -v ERRORS="$ERRORS" \
    -f calculateBBoxEpisodeCount.awk | tail -r >"$LONG_SPREADSHEET"

# Print header for credits file
printf "Person\tJob\tShow_Type\tShow_Title\tCharacter_Name\n" >"$CREDITS"

# Generate credits spreadsheets
sort -fu "$RAW_CREDITS" | sort -fb >>"$CREDITS"
cut -f 1 "$RAW_CREDITS" | sort -fu >>"$UNIQUE_PERSONS"
cut -f 5 "$RAW_CREDITS" | sort -fu >>"$UNIQUE_CHARACTERS"

function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    numlines=$(($(sed -n '$=' "$1") - $2))
    ls -loh "$1" |
        awk -v nl=$numlines '{ printf ("%-45s%6s%6s %s %s %8d lines\n", $8, $4, $5, $6, $7, nl); }'
}

# Output some stats from credits
printf "\n==> Stats from processing credits:\n"
numPersons=$(sed -n '$=' "$UNIQUE_PERSONS")
numCharacters=$(sed -n '$=' "$UNIQUE_CHARACTERS")
printf "%8d people credited\n" "$numPersons"
#
# for i in actor producer director writer other guest narrator; do
for i in actor director; do
    count=$(cut -f 1,2 "$CREDITS" | sort -fu | grep -cw "$i$")
    printf "%8d as %ss\n" "$count" "$i"
done
printf "%8d characters portrayed (in at most" "$numCharacters"
count=$(cut -f 3,4 "$CREDITS" | sort -fu | grep -cw "^tv_show")
printf " %d TV shows)\n" "$count"

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from downloading and processing raw sitemap data:\n"
printAdjustedFileInfo "$SHOW_URLS" 0
printAdjustedFileInfo "$LONG_SPREADSHEET" 1
printAdjustedFileInfo "$SHORT_SPREADSHEET" 1
printAdjustedFileInfo "$EPISODES_CSV" 1
printAdjustedFileInfo "$MOVIES_CSV" 1
printAdjustedFileInfo "$SHOWS_CSV" 1
printAdjustedFileInfo "$UNIQUE_TITLES" 0
printAdjustedFileInfo "$CREDITS" 1
printAdjustedFileInfo "$UNIQUE_PERSONS" 0
printAdjustedFileInfo "$UNIQUE_CHARACTERS" 0

# Shortcut for adding totals to spreadsheets
function addTotalsToSpreadsheet() {
    # Add labels in column A
    # Add totals formula in remaining columns
    colNames=ABCDEFGHIJKLMNOPQRSTU
    ((lastRow = $(sed -n '$=' "$1")))
    ((numCountA = $(head -1 "$1" | awk -F"\t" '{print NF}') - 1))
    TOTAL="Non-blank values"
    for ((i = 1; i <= numCountA; i++)); do
        x=${colNames:i:1}
        TOTAL+="\t=COUNTA(${x}2:${x}$lastRow)"
    done
    printf "$TOTAL\n" >>"$1"
    #
    case "$2" in
    skip)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\n" >>"$1"
        ;;
    sum)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\n" >>"$1"
        ;;
    total)
        TXT_TOTAL=$(cat "$DURATION")
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t$TXT_TOTAL\n" >>"$1"
        ;;
    *)
        printf "==> Bad parameter: addTotalsToSpreadsheet \"$2\" $1\n" >>"$ERRORS"
        ;;
    esac
}

# Output spreadsheet footer if totals requested
# Either skip, sum, or use computed totals from $DURATION
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet "$SHORT_SPREADSHEET" "total"
    addTotalsToSpreadsheet "$LONG_SPREADSHEET" "sum"
    #
    addTotalsToSpreadsheet "$EPISODES_CSV" "sum"
    addTotalsToSpreadsheet "$MOVIES_CSV" "sum"
    addTotalsToSpreadsheet "$SHOWS_CSV" "sum"
fi

# Look for any leftover HTML character codes or other problems
# shellcheck disable=SC2086
probs="$(rg -c --sort path -f rg_problems.rgx \
    $ALL_TXT $ALL_SPREADSHEETS || true)"
if [ -n "$probs" ]; then
    {
        printf "\n==> Possible formatting problems:\n"
        printf "    $probs\n"
        printf "==> For more details:\n"
        printf "    rg -f rg_problems.rgx BBox_[Tu]*$DATE_ID*\n\n"
    } >>"$ERRORS"
fi
#
# Also send to stdout
# shellcheck disable=SC2086
probs="$(rg -c --color ansi --sort path -f rg_problems.rgx \
    $ALL_TXT $ALL_SPREADSHEETS || true)"
if [ -n "$probs" ]; then
    printf "\n==> Possible formatting problems:\n"
    printf "    $probs\n"
    printf "==> For more details:\n"
    printf "    rg -f rg_problems.rgx BBox_[Tu]*$DATE_ID*\n\n"
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        # shellcheck disable=SC2086
        rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
    fi
    exit
fi

# Shortcut for counting occurrences of a string in all spreadsheets
# countOccurrences string
function countOccurrences() {
    # shellcheck disable=SC2086
    grep -H -c "$1" $ALL_SPREADSHEETS "$SHOW_URLS"
}

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs() {
    printf "\n"
    if [ ! -e "$2" ]; then
        printf "==> $2 does not exist. Skipping diff.\n"
        return 1
    fi
    if [ ! -e "$1" ]; then
        # If the basefile file doesn't yet exist, assume no differences
        # and copy the newfile to the basefile so it can serve
        # as a base for diffs in the future.
        printf "==> $1 does not exist. Creating it, assuming no diffs.\n"
        cp -p "$2" "$1"
    else
        # first the stats
        printf "./whatChanged \"$1\" \"$2\"\n"
        diff -u "$1" "$2" | diffstat -sq \
            -D "$(cd "$(dirname "$2")" && pwd -P)" |
            sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
        # then the diffs
        if cmp --quiet "$1" "$2"; then
            printf "==> No diffs found.\n"
        else
            diff -U 0 "$1" "$2" | awk -f formatUnifiedDiffOutput.awk
        fi
    fi
}

# Preserve any possible errors for debugging
# shellcheck disable=SC2086
cat >>"$POSSIBLE_DIFFS" <<EOF
==> ${0##*/} completed: $(date)

### Any duplicate titles?
$(grep "=HYPERLINK" "$SHORT_SPREADSHEET" | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_UNIQUE_TITLES "$UNIQUE_TITLES")
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET "$SHORT_SPREADSHEET")
$(checkdiffs $PUBLISHED_UNIQUE_PERSONS "$UNIQUE_PERSONS")
$(checkdiffs $PUBLISHED_UNIQUE_CHARACTERS "$UNIQUE_CHARACTERS")
$(checkdiffs $PUBLISHED_CREDITS "$CREDITS")
$(checkdiffs $PUBLISHED_SHOW_URLS "$SHOW_URLS")
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET "$LONG_SPREADSHEET")

### These counts should not vary significantly over time
### if they do, the earlier download may have failed.

==> Number of Episodes
$(countOccurrences "/episode/")

==> Number of Movies
$(countOccurrences "/movie/")

==> Number of Shows
$(countOccurrences "/show/")

### Any funny stuff with file lengths?

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    # shellcheck disable=SC2086
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit
