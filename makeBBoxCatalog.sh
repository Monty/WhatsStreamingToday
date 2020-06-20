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
cd $DIRNAME

# Create some timestamps
DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# -a ALT picks alternate files to scrape. The triple "BBoxPrograms, BBoxEpisodes, and BBoxSeasons"
#    are amended with ALT, e.g. BBoxPrograms-$ALT.csv, BBoxEpisodes-$ALT.csv, etc.
# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-s" switch to only output a summary. Delete any created files except anomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":a:drst" opt; do
    case $opt in
    a)
        ALT_ID="-$OPTARG"
        DATE_ID="-$OPTARG"
        ;;
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
    :)
        printf "[Error] Option -$OPTARG requires an argument.\n" >&2
        exit 1
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
SITEMAP_URL="https://prod-bbc-catalog.s3.amazonaws.com/apple_catalogue_feed.xml"
if ! curl -o /dev/null -Isf $SITEMAP_URL; then
    printf "[Error] $SITEMAP_URL isn't available, or your network is down.\n"
    printf "        Try accessing $SITEMAP_URL in your browser.\n"
    exit 1
fi

# Required subdirectories
COLUMNS="BBox-columns"
BASELINE="BBox-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveTodaysBBoxFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results

# In the default case -- input, output, and baseline files have no date information.
#   but intermediate files have today's date $DATE_ID inserted before the file extension.
# If -a ALT_ID is specified, the $ALT_ID string is instead inserted in ALL of those files,
#   most commonly a LONGDATE corresponding to the original scrape time, but it could
#   be any string.
# Error and debugging files always have a LONGDATE of the execution time inserted.

# Error and debugging info (per run)
POSSIBLE_DIFFS="BBox_diffs$LONGDATE.txt"
ERROR_FILE="BBox_anomalies$LONGDATE.txt"

# Downloaded XML file to process
SITEMAP_FILE="$COLUMNS/BBox-sitemap$DATE_ID.xml"

# Final output spreadsheets
SHORT_SPREADSHEET="BBox_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET="BBox_TV_ShowsEpisodes$DATE_ID.csv"

# Intermediate but useful spreadsheet files
CATALOG_SPREADSHEET="$COLUMNS/BBoxCatalog$DATE_ID.csv"
EPISODES_SPREADSHEET="$COLUMNS/BBoxEpisodes$DATE_ID.csv"
MOVIES_SPREADSHEET="$COLUMNS/BBoxMovies$DATE_ID.csv"
PROGRAMS_SPREADSHEET="$COLUMNS/BBoxPrograms$DATE_ID.csv"
SEASONS_SPREADSHEET="$COLUMNS/BBoxSeasons$DATE_ID.csv"

# Intermediate working files
TITLE_FILE="$COLUMNS/uniqTitles$DATE_ID.csv"
DURATION_FILE="$COLUMNS/durations$DATE_ID.csv"

# Saved files used for comparison with current files
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet$ALT_ID.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes$ALT_ID.txt"
#
PUBLISHED_CATALOG_SPREADSHEET="$BASELINE/BBoxCatalog$ALT_ID.txt"
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BBoxEpisodes$ALT_ID.txt"
PUBLISHED_MOVIES_SPREADSHEET="$BASELINE/BBoxMovies$ALT_ID.txt"
PUBLISHED_PROGRAMS_SPREADSHEET="$BASELINE/BBoxPrograms$ALT_ID.txt"
PUBLISHED_SEASONS_SPREADSHEET="$BASELINE/BBoxSeasons$ALT_ID.txt"
#
PUBLISHED_TITLE_FILE="$BASELINE/uniqTitles$ALT_ID.txt"
PUBLISHED_DURATION_FILE="$BASELINE/durations$ALT_ID.txt"

# Filename groups used for cleanup
ALL_WORKING="$TITLE_FILE $DURATION_FILE "
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET $LONG_SPREADSHEET "
ALL_SPREADSHEETS+="$CATALOG_SPREADSHEET $EPISODES_SPREADSHEET $MOVIES_SPREADSHEET "
ALL_SPREADSHEETS+="$PROGRAMS_SPREADSHEET $SEASONS_SPREADSHEET "

# Cleanup any possible leftover files
rm -f $ALL_WORKING
rm -f $ALL_SPREADSHEETS

# Grab the XML file and get rid of Windows CRs
# Unless we already have one from today
if [ ! -e "$SITEMAP_FILE" ]; then
    printf "==> Downloading new $SITEMAP_FILE\n"
    curl -s $SITEMAP_URL | perl -pe 'tr/\r//d' >$SITEMAP_FILE
else
    printf "==> using existing $SITEMAP_FILE\n"
fi

# Print header for error file
printf "### Possible anomalies from processing the sitemap are listed below.\n\n" >$ERROR_FILE

# Make unsorted spreadsheet of all catalog fields
awk -v ERROR_FILE=$ERROR_FILE -f getBBoxCatalogFrom-sitemap.awk $SITEMAP_FILE >$CATALOG_SPREADSHEET

# Field numbers returned by getBBoxCatalogFrom-sitemap.awk
#     1 Sortkey       2 Title           3 Seasons          4 Episodes      5 Duration     6 Year
#     7 Rating        8 Description     9 Content_Type    10 Content_ID   11 Entity_ID   12 Genre
#    13 Show_Type    14 Date_Type      15 Original_Date   16 Show_ID      17 Season_ID   18 Sn_#
#    19 Ep_#         20 1st_#          21 Last_#

# Pick columns to display
if [ "$DEBUG" != "yes" ]; then
    spreadsheet_columns="1-9"
else
    spreadsheet_columns="1-11,16-17,20-21"
fi
titleCol="2"

# Make sorted spreadsheet of all catalog fields that is used to generate final spreadsheets
head -1 $CATALOG_SPREADSHEET | cut -f $spreadsheet_columns >$LONG_SPREADSHEET
tail -n +2 $CATALOG_SPREADSHEET | cut -f $spreadsheet_columns | sort -u >>$LONG_SPREADSHEET

# Generate final spreadsheets
grep -e "^Sortkey" -e "tv_movie" -e "tv_show" $LONG_SPREADSHEET >$SHORT_SPREADSHEET
grep -e "^Sortkey" -e "tv_episode" $LONG_SPREADSHEET >$EPISODES_SPREADSHEET
grep -e "^Sortkey" -e "tv_movie" $LONG_SPREADSHEET >$MOVIES_SPREADSHEET
grep -e "^Sortkey" -e "tv_show" $LONG_SPREADSHEET >$PROGRAMS_SPREADSHEET
grep -e "^Sortkey" -e "tv_season" $LONG_SPREADSHEET >$SEASONS_SPREADSHEET
#
grep -v "^Sortkey" $SHORT_SPREADSHEET | cut -f $titleCol | sort -u >$TITLE_FILE

function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    filesize=$(ls -loh $1 | cut -c 22-26)
    filedate=$(ls -loh $1 | cut -c 28-39)
    numlines=$(($(sed -n '$=' $1) - $2))
    printf "%-37s%6s%15s%9d lines\n" "$1" "$filesize" "$filedate" "$numlines"
}

# Output some stats
printf "\n==> Stats from downloading and processing raw catalog data:\n"
printAdjustedFileInfo $SITEMAP_FILE 0
# Details from SITEMAP_FILE
head -4 $SITEMAP_FILE | tail -2 |
    awk -F"[<>]" '{printf ("    %s: %s", $2, $3)}'
#
printf "\n---\n"
printAdjustedFileInfo $CATALOG_SPREADSHEET 1

# Shortcut for adding totals to spreadsheets
function addTotalsToSpreadsheet() {
    # Add labels in column B
    # Add totals formula in remaining columns
    colNames=BCDEFGHIJKLMNOPQRSTU
    ((lastRow = $(sed -n '$=' $1)))
    ((numCountA = $(head -1 $1 | awk -F"\t" '{print NF}') - 2))
    TOTAL="\tNon-blank values"
    for (( i=1; i<=$numCountA; i++ )); do
        x=${colNames:$i:1}
        TOTAL+="\t=COUNTA(${x}2:${x}$lastRow)"
    done
    printf "$TOTAL\n" >>$1
    # Number of seasons & episodes not yet implemented
    printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\n" >>$1
}

# Output spreadsheet footer if totals requested
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet $SHORT_SPREADSHEET
    addTotalsToSpreadsheet $LONG_SPREADSHEET
    #
    addTotalsToSpreadsheet $EPISODES_SPREADSHEET
    addTotalsToSpreadsheet $MOVIES_SPREADSHEET
    addTotalsToSpreadsheet $PROGRAMS_SPREADSHEET
    addTotalsToSpreadsheet $SEASONS_SPREADSHEET
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        rm -f $ALL_WORKING
        rm -f $ALL_SPREADSHEETS
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
    if [ ! -e "$1" ]; then
        # If the basefile file doesn't yet exist, assume no differences
        # and copy the newfile to the basefile so it can serve
        # as a base for diffs in the future.
        printf "==> $1 does not exist. Creating it, assuming no diffs.\n"
        cp -p "$2" "$1"
    else
        printf "==> what changed between $1 and $2:\n"
        # first the stats
        diff -c "$1" "$2" | diffstat -sq \
            -D $(cd $(dirname "$2") && pwd -P) |
            sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
        # then the diffs
        diff \
            --unchanged-group-format='' \
            --old-group-format='==> deleted %dn line%(n=1?:s) at line %df <==
%<' \
            --new-group-format='==> added %dN line%(N=1?:s) after line %de <==
%>' \
            --changed-group-format='==> changed %dn line%(n=1?:s) at line %df <==
%<------ to:
%>' "$1" "$2"
        if [ $? == 0 ]; then
            printf "==> no diffs found.\n"
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Any duplicate titles?
$(grep -v "^Sortkey" $SHORT_SPREADSHEET | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_TITLE_FILE $TITLE_FILE)
$(checkdiffs $PUBLISHED_CATALOG_SPREADSHEET $CATALOG_SPREADSHEET)

### These counts should not vary significantly over time
### if they do, the earlier download may have failed.

==> Number of Episodes
$(countOccurrences "tv_episode")

==> Number of Movies
$(countOccurrences "tv_movie")

==> Number of Programs
$(countOccurrences "tv_show")

==> Number of Seasons
$(countOccurrences "tv_season")

### Any funny stuff with file lengths?

$(wc $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING
    rm -f $ALL_SPREADSHEETS
fi

exit
