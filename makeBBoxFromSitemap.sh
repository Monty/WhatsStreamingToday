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
# Use "-r" switch to remove shows that are no longer available
# Use "-s" switch to only output a summary. Delete any created files except anomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":drst" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    r)
        REMOVE="yes"
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

# Downloaded XML file to process
SITEMAP="$COLS/BBox-sitemap$DATE_ID.xml"

# Final output spreadsheets
SHORT_SPREADSHEET="BBox_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET="BBox_TV_ShowsEpisodes$DATE_ID.csv"

# Intermediate but useful spreadsheet files
EPISODES_SPREADSHEET="$COLS/BBoxEpisodes$DATE_ID.csv"
MOVIES_SPREADSHEET="$COLS/BBoxMovies$DATE_ID.csv"
SEASONS_SPREADSHEET="$COLS/BBoxSeasons$DATE_ID.csv"
SHOWS_SPREADSHEET="$COLS/BBoxShows$DATE_ID.csv"

# HTML files segregated by item type
TV_EPISODE_ITEMS="$COLS/tv_episodes$DATE_ID.html"
TV_MOVIE_ITEMS="$COLS/tv_movies$DATE_ID.html"
TV_SEASON_ITEMS="$COLS/tv_seasons$DATE_ID.html"
TV_SHOW_ITEMS="$COLS/tv_shows$DATE_ID.html"

# Files used to remove missing shows
TEMP_SPREADSHEET="$COLS/temp_spreadsheet.csv"
ALL_URLS="$COLS/all_URLs$DATE_ID.csv"

# Intermediate working files
RAW_TITLES="$COLS/rawTitles$DATE_ID.txt"
UNIQUE_TITLES="BBox_uniqTitles$DATE_ID.txt"
DURATION="$COLS/total_duration$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BBoxEpisodes.txt"
PUBLISHED_MOVIES_SPREADSHEET="$BASELINE/BBoxMovies.txt"
PUBLISHED_SEASONS_SPREADSHEET="$BASELINE/BBoxCatalog.txt"
PUBLISHED_SHOWS_SPREADSHEET="$BASELINE/BBoxShows.txt"
#
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
PUBLISHED_DURATION="$BASELINE/total_duration.txt"
#
PUBLISHED_ALL_URLS="$BASELINE/all_URLs.csv"

# Filename groups used for cleanup
ALL_WORKING="$RAW_TITLES $UNIQUE_TITLES $DURATION"
#
ALL_HTML="$TV_EPISODE_ITEMS $TV_MOVIE_ITEMS $TV_SEASON_ITEMS $TV_SHOW_ITEMS"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET $LONG_SPREADSHEET "
ALL_SPREADSHEETS+="$EPISODES_SPREADSHEET $MOVIES_SPREADSHEET "
ALL_SPREADSHEETS+="$SEASONS_SPREADSHEET $SHOWS_SPREADSHEET"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_SPREADSHEETS

# Grab the XML catalog file and extract the URLs for en-us items
# Unless we already have one from today
if [ ! -e "$ALL_URLS" ]; then
    printf "==> Downloading new $ALL_URLS\n"
    curl -s $SITEMAP_URL | rg en-us | awk -f getBBoxURLsFromSitemap.awk >"$ALL_URLS"
else
    printf "==> using existing $ALL_URLS\n"
fi

# Get HTML for movies
# Unless we already have one from today
if [ ! -e "$TV_MOVIE_ITEMS" ]; then
    printf "==> Generating new $TV_MOVIE_ITEMS\n"
    while read -r url; do
        curl -s "$url" | rg -N -f rg_movies.rgx |
            perl -pe 's+&quot;+"+g' >>"$TV_MOVIE_ITEMS"
    done < <(rg -N /movie/ "$ALL_URLS" )
else
    printf "==> using existing $TV_MOVIE_ITEMS\n"
fi

# Print header for error file
printf "### Possible anomalies from processing $TV_MOVIE_ITEMS\n\n" >"$ERRORS"

awk -v ERRORS="$ERRORS" -v RAW_TITLES="$RAW_TITLES" -f getBBoxMoviesFromHTML.awk \
"$TV_MOVIE_ITEMS" | sort -fu --key=4 --field-separator=\" >"$MOVIES_SPREADSHEET"

# Sort the titles produced by getBBoxCatalogFromSitemap.awk
sort -fu $RAW_TITLES >$UNIQUE_TITLES
# rm -f $RAW_TITLES


# Field numbers returned by getBBo*MoviesFromHTML.awk
#     1 Title           2 Seasons      3 Episodes       4 Duration     5 Genre       6 Year
#     7 Rating          8 Description  9 Content_Type  10 Content_ID  11 Show_Type  12 Date_Type
#    13 Original_Date  14 Sn_#        15 Ep_#          16 1st_#       17 Last_#

titleCol="1"

# Pick columns to display
# NOTE: Content_Type is required for calculateBBoxShowDurations.awk
if [ "$DEBUG" != "yes" ]; then
    spreadsheet_columns="1-9"
else
    spreadsheet_columns="1-17"
fi

# Generate SHORT_SPREADSHEET by processing LONG_SPREADSHEET to calculate and include durations
sed -n '1!G;h;$p' $LONG_SPREADSHEET | awk -v ERRORS=$ERRORS -v DURATION="$DURATION" \
    -f calculateBBoxShowDurations.awk | sed -n '1!G;h;$p' >$SHORT_SPREADSHEET

function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    numlines=$(($(sed -n '$=' $1) - $2))
    ls -loh $1 |
        awk -v nl=$numlines '{ printf ("%-45s%6s%6s %s %s %8d lines\n", $8, $4, $5, $6, $7, nl); }'
}

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from downloading and processing raw sitemap data:\n"
printAdjustedFileInfo $LONG_SPREADSHEET 1
printAdjustedFileInfo $SHORT_SPREADSHEET 1
printAdjustedFileInfo $UNIQUE_TITLES 0
printAdjustedFileInfo $EPISODES_SPREADSHEET 1
printAdjustedFileInfo $MOVIES_SPREADSHEET 1
printAdjustedFileInfo $SEASONS_SPREADSHEET 1
printAdjustedFileInfo $SHOWS_SPREADSHEET 1

# Shortcut for adding totals to spreadsheets
function addTotalsToSpreadsheet() {
    # Add labels in column B
    # Add totals formula in remaining columns
    colNames=BCDEFGHIJKLMNOPQRSTU
    ((lastRow = $(sed -n '$=' $1)))
    ((numCountA = $(head -1 $1 | awk -F"\t" '{print NF}') - 2))
    TOTAL="\tNon-blank values"
    for ((i = 1; i <= numCountA; i++)); do
        x=${colNames:i:1}
        TOTAL+="\t=COUNTA(${x}2:${x}$lastRow)"
    done
    printf "$TOTAL\n" >>$1
    #
    case "$2" in
    skip)
        printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\n" >>$1
        ;;
    sum)
        printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t=SUM(E2:E$lastRow)\n" >>$1
        ;;
    total)
        TXT_TOTAL=$(cat $DURATION)
        printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t$TXT_TOTAL\n" >>$1
        ;;
    *)
        printf "==> Bad parameter: addTotalsToSpreadsheet \"$2\" $1\n" >>$ERRORS
        ;;
    esac
}

# Output spreadsheet footer if totals requested
# Either skip, sum, or use computed totals from $DURATION
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet $SHORT_SPREADSHEET "sum"
    addTotalsToSpreadsheet $LONG_SPREADSHEET "sum"
    #
    addTotalsToSpreadsheet $EPISODES_SPREADSHEET "sum"
    addTotalsToSpreadsheet $MOVIES_SPREADSHEET "sum"
    addTotalsToSpreadsheet $SEASONS_SPREADSHEET "sum"
    addTotalsToSpreadsheet $SHOWS_SPREADSHEET "sum"
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        rm -f $ALL_WORKING $ALL_SPREADSHEETS
    fi
    exit
fi

# Shortcut for counting occurrences of a string in all spreadsheets
# countOccurrences string
function countOccurrences() {
    grep -H -c "$1" $ALL_SPREADSHEETS
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
$(checkdiffs $PUBLISHED_DURATION $DURATION)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET)

### These counts should not vary significantly over time
### if they do, the earlier download may have failed.

==> Number of Episodes
$(countOccurrences "tv_episode")

==> Number of Movies
$(countOccurrences "tv_movie")

==> Number of Shows
$(countOccurrences "tv_show")

### Any funny stuff with file lengths?

$(wc $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING $ALL_SPREADSHEETS
fi

exit
