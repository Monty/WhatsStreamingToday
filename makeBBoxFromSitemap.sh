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
SITEMAP_URL="https://prod-bbc-catalog.s3.amazonaws.com/apple_catalogue_feed.xml"
if ! curl -o /dev/null -Isf $SITEMAP_URL; then
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
CREDITS="BBox_TV_Credits$DATE_ID.csv"
SHORT_SPREADSHEET="BBox_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET="BBox_TV_ShowsEpisodes$DATE_ID.csv"

# Intermediate but useful spreadsheet files
CATALOG_SPREADSHEET="$COLS/BBoxCatalog$DATE_ID.csv"
EPISODES_SPREADSHEET="$COLS/BBoxEpisodes$DATE_ID.csv"
MOVIES_SPREADSHEET="$COLS/BBoxMovies$DATE_ID.csv"
PROGRAMS_SPREADSHEET="$COLS/BBoxPrograms$DATE_ID.csv"

# XML files segregated by item type
TV_MOVIE_ITEMS="$COLS/tv_movies$DATE_ID.xml"
TV_SHOW_ITEMS="$COLS/tv_shows$DATE_ID.xml"
TV_SEASON_ITEMS="$COLS/tv_seasons$DATE_ID.xml"
TV_EPISODE_ITEMS="$COLS/tv_episodes$DATE_ID.xml"

# Text files containing only <item lines
# (much shorter than xml files to use when searching for contentIds)
IDS_SEASONS="$COLS/ids_seasons$DATE_ID.txt"
IDS_EPISODES="$COLS/ids_episodes$DATE_ID.txt"

# Files used to remove missing shows
ALL_URLS="$COLS/all_URLs$DATE_ID.txt"
MISSING_URLS="$COLS/missing_URLs$DATE_ID.txt"
MISSING_IDS="$COLS/missing_IDs$DATE_ID.txt"

# Intermediate working files
SORTED_SITEMAP="$COLS/BBox-sitemap_sorted$DATE_ID.xml"
RAW_CREDITS="$COLS/rawCredits$DATE_ID.txt"
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
PUBLISHED_CATALOG_SPREADSHEET="$BASELINE/BBoxCatalog.txt"
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BBoxEpisodes.txt"
PUBLISHED_MOVIES_SPREADSHEET="$BASELINE/BBoxMovies.txt"
PUBLISHED_PROGRAMS_SPREADSHEET="$BASELINE/BBoxPrograms.txt"
#
PUBLISHED_UNIQUE_PERSONS="$BASELINE/uniqPersons.txt"
PUBLISHED_UNIQUE_CHARACTERS="$BASELINE/uniqCharacters.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
PUBLISHED_DURATION="$BASELINE/total_duration.txt"
#
PUBLISHED_ALL_URLS="$BASELINE/all_URLs$DATE_ID.txt"
PUBLISHED_MISSING_URLS="$BASELINE/missing_URLs$DATE_ID.txt"

# Filename groups used for cleanup
ALL_WORKING="$SORTED_SITEMAP $RAW_CREDITS $RAW_TITLES $UNIQUE_PERSONS "
ALL_WORKING+="$UNIQUE_CHARACTERS $UNIQUE_TITLES $DURATION"
#
ALL_XML="$TV_MOVIE_ITEMS $TV_SHOW_ITEMS $TV_SEASON_ITEMS $TV_EPISODE_ITEMS"
ALL_TXT="$IDS_SEASONS $IDS_EPISODES"
if [ "$REMOVE" = "yes" ]; then
    ALL_TXT+=" $ALL_URLS $MISSING_URLS $MISSING_IDS"
fi
#
ALL_SPREADSHEETS="$CREDITS $SHORT_SPREADSHEET $LONG_SPREADSHEET "
ALL_SPREADSHEETS+="$CATALOG_SPREADSHEET $EPISODES_SPREADSHEET "
ALL_SPREADSHEETS+="$MOVIES_SPREADSHEET $PROGRAMS_SPREADSHEET"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_XML $ALL_TXT $ALL_SPREADSHEETS

# Grab the XML catalog file and get rid of Windows CRs
# Unless we already have one from today
if [ ! -e "$SITEMAP" ]; then
    printf "==> Downloading new $SITEMAP\n"
    curl -s $SITEMAP_URL | perl -pe 'tr/\r//d' >$SITEMAP
else
    printf "==> using existing $SITEMAP\n"
fi

# Print header for error file
printf "### Possible anomalies from processing $SITEMAP are listed below.\n\n" >$ERRORS

# Pre-sort XML catalog file into four files sorted by item type
awk -v ERRORS=$ERRORS -v TV_MOVIE_ITEMS=$TV_MOVIE_ITEMS -v TV_SHOW_ITEMS=$TV_SHOW_ITEMS \
    -v TV_SEASON_ITEMS=$TV_SEASON_ITEMS -v TV_EPISODE_ITEMS=$TV_EPISODE_ITEMS \
    -v IDS_SEASONS=$IDS_SEASONS -v IDS_EPISODES=$IDS_EPISODES \
    -f sortBBoxItemsFromSitemap.awk $SITEMAP

# Create sorted XML catalog file which is sorted by item type, preserving lines preceding first item
grep -B99 -m 1 "<item" $SITEMAP | grep -v "<item" >$SORTED_SITEMAP
printf "\n" >>$SORTED_SITEMAP
cat $ALL_XML >>$SORTED_SITEMAP

# Make an unsorted spreadsheet of all catalog fields; save an unsorted list of titles
awk -v ERRORS=$ERRORS -v IDS_SEASONS=$IDS_SEASONS -v IDS_EPISODES=$IDS_EPISODES \
    -v RAW_TITLES=$RAW_TITLES -v RAW_CREDITS=$RAW_CREDITS -f getBBoxCatalogFromSitemap.awk \
    $SORTED_SITEMAP >$CATALOG_SPREADSHEET

# Sort the titles produced by getBBoxCatalogFromSitemap.awk
sort -fu $RAW_TITLES >$UNIQUE_TITLES
rm -f $RAW_TITLES

# Field numbers returned by getBBoxCatalogFromSitemap.awk
#     1 Sortkey       2 Title         3 Seasons          4 Episodes         5 Duration      6 Genre
#     7 Year          8 Rating        9 Description     10 Content_Type    11 Content_ID   12 Show_Type
#    13 Date_Type    14 Date_Type    15 Show_ID         16 Season_ID       17 Sn_#         18 Ep_#
#    19 1st_#        20 Last_#
titleCol="2"

# Pick columns to display
# NOTE: Content_Type is required for calculateBBoxShowDurations.awk
if [ "$DEBUG" != "yes" ]; then
    spreadsheet_columns="1-10"
else
    spreadsheet_columns="1-13,16-18"
fi

# Make sorted spreadsheet of all catalog fields that is used to generate final spreadsheets
head -1 $CATALOG_SPREADSHEET | cut -f $spreadsheet_columns >$LONG_SPREADSHEET
tail -n +2 $CATALOG_SPREADSHEET | cut -f $spreadsheet_columns | sort -fu >>$LONG_SPREADSHEET

# Generate credits spreadsheets
head -1 $RAW_CREDITS >$CREDITS
cut -f 1 $CREDITS >$UNIQUE_PERSONS
cut -f 5 $CREDITS >$UNIQUE_CHARACTERS
tail -n +2 $RAW_CREDITS | sort -fu >>$CREDITS
tail -n +2 $CREDITS | cut -f 1 | sort -fu >>$UNIQUE_PERSONS
tail -n +2 $CREDITS | cut -f 5 | grep -v "^$" | sort -fu >>$UNIQUE_CHARACTERS

# Generate final spreadsheets
grep -e "^Sortkey" -e "tv_episode" $LONG_SPREADSHEET >$EPISODES_SPREADSHEET
grep -e "^Sortkey" -e "tv_movie" $LONG_SPREADSHEET >$MOVIES_SPREADSHEET
grep -e "^Sortkey" -e "tv_show" $LONG_SPREADSHEET >$PROGRAMS_SPREADSHEET

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

# Output some stats from credits
printf "\n==> Stats from processing credits:\n"
numPersons=$(sed -n '$=' $UNIQUE_PERSONS)
numCharacters=$(sed -n '$=' $UNIQUE_CHARACTERS)
printf "%8d people credited -- some in more than one job function\n" "$numPersons"
#
# for i in $(cut -f 2 BBox_TV_Credits-200820.csv | tail -n +2 | sort -u); do
for i in actor producer director writer other guest narrator; do
    count=$(cut -f 1,2 $CREDITS | sort -fu | grep -cw "$i$")
    printf "%8d as %ss\n" "$count" "$i"
done
#
printf "%8d characters portrayed in" "$numCharacters"
count=$(cut -f 3,4 $CREDITS | sort -fu | grep -cw "^tv_movie")
printf " %d movies" "$count"
count=$(cut -f 3,4 $CREDITS | sort -fu | grep -cw "^tv_show")
printf " and %d TV shows\n" "$count"

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from downloading and processing raw sitemap data:\n"
printAdjustedFileInfo $SORTED_SITEMAP 0
printAdjustedFileInfo $CATALOG_SPREADSHEET 1
printAdjustedFileInfo $LONG_SPREADSHEET 1
printAdjustedFileInfo $IDS_EPISODES 0
printAdjustedFileInfo $CREDITS 1
printAdjustedFileInfo $UNIQUE_PERSONS 0
printAdjustedFileInfo $UNIQUE_CHARACTERS 0
printAdjustedFileInfo $IDS_SEASONS 0
printAdjustedFileInfo $SHORT_SPREADSHEET 1
printAdjustedFileInfo $UNIQUE_TITLES 0
printAdjustedFileInfo $PROGRAMS_SPREADSHEET 1
printAdjustedFileInfo $MOVIES_SPREADSHEET 1
#
# Details from SORTED_SITEMAP
grep -m 1 '<totalItemCount>' $SORTED_SITEMAP | awk -F"[<>]" '{printf ("    %s:    %s\n", $2, $3)}'
grep -m 1 '<lastBuildDate>' $SORTED_SITEMAP | awk -F"[<>]" '{printf ("    %s:     %s\n\n", $2, $3)}'

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
    addTotalsToSpreadsheet $SHORT_SPREADSHEET "total"
    addTotalsToSpreadsheet $LONG_SPREADSHEET "sum"
    #
    addTotalsToSpreadsheet $EPISODES_SPREADSHEET "sum"
    addTotalsToSpreadsheet $MOVIES_SPREADSHEET "sum"
    addTotalsToSpreadsheet $PROGRAMS_SPREADSHEET "skip"
fi

# Generate list of missing URLs
if [ "$REMOVE" = "yes" ]; then
    rg '=HYPERLINK' $SHORT_SPREADSHEET | cut -f 1-2 |
        sed -e 's/=HYPERLINK("//' -e 's/".*//' -e 's/.* //' >$ALL_URLS
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        rm -f $ALL_WORKING $ALL_XML $ALL_TXT $ALL_SPREADSHEETS
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
$(grep "=HYPERLINK" $SHORT_SPREADSHEET | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_UNIQUE_PERSONS $UNIQUE_PERSONS)
$(checkdiffs $PUBLISHED_UNIQUE_CHARACTERS $UNIQUE_CHARACTERS)
$(checkdiffs $PUBLISHED_CREDITS $CREDITS)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET)
$(checkdiffs $PUBLISHED_DURATION $DURATION)

### These counts should not vary significantly over time
### if they do, the earlier download may have failed.

==> Number of Episodes
$(countOccurrences "tv_episode")

==> Number of Movies
$(countOccurrences "tv_movie")

==> Number of Programs
$(countOccurrences "tv_show")

### Any funny stuff with file lengths?

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING $ALL_XML $ALL_TXT $ALL_SPREADSHEETS
fi

exit
