#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on BritBox

# trap ctrl-c and call cleanup
trap cleanup INT
#
function cleanup() {
    printf "\n"
    exit 130
}

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
while getopts ":dst" opt; do
    case $opt in
    d)
        DEBUG="yes"
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
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    printf "[Error] Can't run curl. Install curl and rerun this script.\n"
    printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
    exit 1
fi

# Make sure network is up and BritBox site is reachable
SITEMAP_URL="https://www.britbox.com/dynamic-sitemap.xml"
if ! curl -o /dev/null -Is $SITEMAP_URL; then
    printf "[Error] $SITEMAP_URL isn't available, or your network is down.\n"
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
ALL_URLS="$COLS/all_URLs$DATE_ID.txt"

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
TV_SEASON_TXT="$COLS/tv_seasons$DATE_ID.txt"
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
PUBLISHED_EPISODES_CSV="$BASELINE/BBoxEpisodes.txt"
PUBLISHED_MOVIES_CSV="$BASELINE/BBoxMovies.txt"
PUBLISHED_SHOWS_CSV="$BASELINE/BBoxShows.txt"
#
PUBLISHED_UNIQUE_PERSONS="$BASELINE/uniqPersons.txt"
PUBLISHED_UNIQUE_CHARACTERS="$BASELINE/uniqCharacters.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
PUBLISHED_DURATION="$BASELINE/total_duration.txt"
#
PUBLISHED_ALL_URLS="$BASELINE/all_URLs.txt"

# Filename groups used for cleanup
ALL_WORKING="$RAW_CREDITS $RAW_TITLES $TEMP_SPREADSHEET"
#
ALL_TXT="$UNIQUE_PERSONS $UNIQUE_CHARACTERS $UNIQUE_TITLES $DURATION"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET $LONG_SPREADSHEET $CREDITS"
#
ALL_CSVS="$MOVIES_CSV $SHOWS_CSV $EPISODES_CSV"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS

# Print header for credits file
printf "Person\tJob\tShow_Type\tShow_Title\tCharacter_Name\n" >$CREDITS

# Grab the sitemap file and extract the URLs for en-us items
# Unless we already have one from today
if [ ! -e "$ALL_URLS" ]; then
    printf "==> Downloading new $ALL_URLS\n"
    curl -s $SITEMAP_URL | rg en-us |
        awk -f getBBoxURLsFromSitemap.awk | sort -fu >"$ALL_URLS"
else
    printf "==> using existing $ALL_URLS\n"
fi

function winnowHTML() {
    printf "==> Generating new $2\n"
    while read -r url; do
        FILE="$url"
        curl -s "$url" | rg -f rg_BBox_keep.rgx | sd '&quot;' '"' |
            sd '"type":"(movie|episode|show|season)"' '\n"type":"$1"' |
            sd '"offers".*' '' | sd '"subtype":"",' '' |
            sd '"path":"",' '' | sd '^[[:space:]]+' '' |
            rg -v -f rg_BBox_skip.rgx | sort -ur |
            awk -v FILE="$FILE" -f getBBox-preprocess.awk >>"$2"
    done < <(rg -N "$1" "$ALL_URLS")
}

# Get data for movies from /movie/ URLs
# Unless we already have one from today
if [ ! -e "$TV_MOVIE_TXT" ]; then
    winnowHTML "/movie/" "$TV_MOVIE_TXT"
else
    printf "==> using existing $TV_MOVIE_TXT\n"
fi
# Generate movies spreadsheet
printf "### Possible anomalies from processing $TV_MOVIE_TXT\n" >"$ERRORS"
awk -v ERRORS="$ERRORS" -v RAW_TITLES="$RAW_TITLES" -v RAW_CREDITS=$RAW_CREDITS \
    -f getBBoxMovies.awk "$TV_MOVIE_TXT" |
    sort -fu --key=4 --field-separator=\" >"$MOVIES_CSV"

# Get data for shows from /show/ URLs
# Unless we already have one from today
if [ ! -e "$TV_SHOW_TXT" ]; then
    winnowHTML "/show/" "$TV_SHOW_TXT"
else
    printf "==> using existing $TV_SHOW_TXT\n"
fi
# Generate shows spreadsheet
printf "\n### Possible anomalies from processing $TV_SHOW_TXT\n" >>"$ERRORS"
awk -v ERRORS="$ERRORS" -v RAW_TITLES="$RAW_TITLES" -v RAW_CREDITS=$RAW_CREDITS \
    -f getBBoxShows.awk "$TV_SHOW_TXT" |
    sort -fu --key=4 --field-separator=\" >"$SHOWS_CSV"

# Get data for episodes from /season/ URLs
# Unless we already have one from today
if [ ! -e "$TV_EPISODE_TXT" ]; then
    winnowHTML "/season/" "$TV_EPISODE_TXT"
else
    printf "==> using existing $TV_EPISODE_TXT\n"
fi
# Generate episodes spreadsheet
printf "\n### Possible anomalies from processing $TV_EPISODE_TXT\n" >>"$ERRORS"
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
touch $ALL_SPREADSHEETS $ALL_CSVS
# Make TEMP_SPREADSHEET containing ALL columns
head -1 "$MOVIES_CSV" >"$TEMP_SPREADSHEET"
rg -I '=HYPERLINK' $ALL_CSVS |
    sort -fu --key=4 --field-separator=\" >>"$TEMP_SPREADSHEET"
# Make LONG_SPREADSHEET containing selected columne
cut -f $spreadsheet_columns "$TEMP_SPREADSHEET" >"$LONG_SPREADSHEET"
# Make SHORT_SPREADSHEET by adding up durations from LONG_SPREADSHEET
tail -r "$LONG_SPREADSHEET" | awk -v ERRORS="$ERRORS" -v DURATION="$DURATION" \
    -f calculateBBoxShowDurations.awk | tail -r >>"$SHORT_SPREADSHEET"

# Generate credits spreadsheets
sort -fu $RAW_CREDITS | sort -fb >>$CREDITS
cut -f 1 $RAW_CREDITS | sort -fu >>$UNIQUE_PERSONS
cut -f 5 $RAW_CREDITS | sort -fu >>$UNIQUE_CHARACTERS

function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    numlines=$(($(sed -n '$=' $1) - $2))
    ls -loh $1 |
        awk -v nl=$numlines '{ printf ("%-45s%6s%6s %s %s %8d lines\n", $8, $4, $5, $6, $7, nl); }'
}

# Output some stats from credits
printf "\n==> Stats from processing credits:\n"
numPersons=$(sed -n '$=' $UNIQUE_PERSONS)
numCharacters=$(sed -n '$=' $UNIQUE_CHARACTERS)
printf "%8d people credited\n" "$numPersons"
#
# for i in actor producer director writer other guest narrator; do
for i in actor director; do
    count=$(cut -f 1,2 $CREDITS | sort -fu | grep -cw "$i$")
    printf "%8d as %ss\n" "$count" "$i"
done
printf "%8d characters portrayed (in at most" "$numCharacters"
count=$(cut -f 3,4 $CREDITS | sort -fu | grep -cw "^tv_show")
printf " %d TV shows)\n" "$count"

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from downloading and processing raw sitemap data:\n"
printAdjustedFileInfo $ALL_URLS 0
printAdjustedFileInfo $LONG_SPREADSHEET 1
printAdjustedFileInfo $SHORT_SPREADSHEET 1
printAdjustedFileInfo $EPISODES_CSV 1
printAdjustedFileInfo $MOVIES_CSV 1
printAdjustedFileInfo $SHOWS_CSV 1
printAdjustedFileInfo $UNIQUE_TITLES 0
printAdjustedFileInfo $CREDITS 1
printAdjustedFileInfo $UNIQUE_PERSONS 0
printAdjustedFileInfo $UNIQUE_CHARACTERS 0

# Shortcut for adding totals to spreadsheets
function addTotalsToSpreadsheet() {
    # Add labels in column A
    # Add totals formula in remaining columns
    colNames=ABCDEFGHIJKLMNOPQRSTU
    ((lastRow = $(sed -n '$=' $1)))
    ((numCountA = $(head -1 $1 | awk -F"\t" '{print NF}') - 1))
    TOTAL="Non-blank values"
    for ((i = 1; i <= numCountA; i++)); do
        x=${colNames:i:1}
        TOTAL+="\t=COUNTA(${x}2:${x}$lastRow)"
    done
    printf "$TOTAL\n" >>$1
    #
    case "$2" in
    skip)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\n" >>$1
        ;;
    sum)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\n" >>$1
        ;;
    total)
        TXT_TOTAL=$(cat $DURATION)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t$TXT_TOTAL\n" >>$1
        ;;
    *)
        printf "==> Bad parameter: addTotalsToSpreadsheet \"$2\" $1\n" >>"$ERRORS"
        ;;
    esac
}

# Output spreadsheet footer if totals requested
# Either skip, sum, or use computed totals from $DURATION
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet $SHORT_SPREADSHEET "total"
    addTotalsToSpreadsheet $LONG_SPREADSHEET "sum"
    #
    addTotalsToSpreadsheet $EPISODES_CSV "sum"
    addTotalsToSpreadsheet $MOVIES_CSV "sum"
    addTotalsToSpreadsheet $SHOWS_CSV "sum"
fi

# Look for any leftover TXT character codes or other problems
probs="$(rg -c --sort path -f rg_problems.rgx $ALL_TXT $ALL_SPREADSHEETS)"
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
probs="$(rg -c --color ansi --sort path -f rg_problems.rgx \
    $ALL_TXT $ALL_SPREADSHEETS)"
if [ -n "$probs" ]; then
    printf "\n==> Possible formatting problems:\n"
    printf "    $probs\n"
    printf "==> For more details:\n"
    printf "    rg -f rg_problems.rgx BBox_[Tu]*$DATE_ID*\n\n"
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
    fi
    exit
fi

# Shortcut for counting occurrences of a string in all spreadsheets
# countOccurrences string
function countOccurrences() {
    grep -H -c "$1" $ALL_SPREADSHEETS "$ALL_URLS"
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
            -D $(cd $(dirname "$2") && pwd -P) |
            sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
        # then the diffs
        if cmp --quiet "$1" "$2"; then
            printf "==> no diffs found.\n"
        else
            diff -U 0 "$1" "$2" | awk -f formatUnifiedDiffOutput.awk
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Any duplicate titles?
$(grep "=HYPERLINK" $SHORT_SPREADSHEET | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET)
$(checkdiffs $PUBLISHED_UNIQUE_PERSONS $UNIQUE_PERSONS)
$(checkdiffs $PUBLISHED_UNIQUE_CHARACTERS $UNIQUE_CHARACTERS)
$(checkdiffs $PUBLISHED_CREDITS $CREDITS)
$(checkdiffs $PUBLISHED_ALL_URLS $ALL_URLS)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET)

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
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit
