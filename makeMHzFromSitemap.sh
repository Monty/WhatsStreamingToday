#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on MHz Choice

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
# Use "-s" switch to only output a summary. Delete any created files except anomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":dqst" opt; do
    case $opt in
    q)
        QUICK="yes"
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
    esac
done

# Make sure we can execute curl.
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    printf "[Error] Can't run curl. Install curl and rerun this script.\n"
    printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
    exit 1
fi

# Make sure network is up and MHz Choice site is reachable
SITEMAP_URL="https://watch.mhzchoice.com/sitemap.xml"
if ! curl -o /dev/null -Isf $SITEMAP_URL; then
    printf "[Error] $SITEMAP_URL isn't available, or your network is down.\n"
    printf "        Try accessing $SITEMAP_URL in your browser.\n"
    exit 1
fi

# Required subdirectories
COLS="MHz-columns"
BASELINE="MHz-baseline"
mkdir -p $COLS $BASELINE

# File names are used in saveTodaysMHzFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results

# In the default case -- input, output, and baseline files have no date information.
#   but intermediate files have today's date $DATE_ID inserted before the file extension.
# Error and debugging files always have a LONGDATE of the execution time inserted.

# Error and debugging info (per run)
POSSIBLE_DIFFS="MHz_diffs$LONGDATE.txt"
ERRORS="MHz_anomalies$LONGDATE.txt"

# Final output spreadsheets
CREDITS="MHz_TV_Credits$DATE_ID.csv"
AVG_SPREADSHEET="MHz_TV_Shows_Avg$DATE_ID.csv"
SHORT_SPREADSHEET="MHz_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET="MHz_TV_ShowsEpisodes$DATE_ID.csv"

# Basic URL files - all, episodes only, seasons only
MHZ_URLS="$COLS/MHz_urls$DATE_ID.txt"
EPISODE_URLS="$COLS/episode_urls$DATE_ID.txt"
SEASON_URLS="$COLS/season_urls$DATE_ID.txt"

# Intermediate working files
UNSORTED="$COLS/unsorted$DATE_ID.txt"
RAW_CREDITS="$COLS/rawCredits$DATE_ID.txt"
RAW_TITLES="$COLS/rawTitles$DATE_ID.txt"
UNIQUE_PERSONS="MHz_uniqPersons$DATE_ID.txt"
UNIQUE_CHARACTERS="MHz_uniqCharacters$DATE_ID.txt"
UNIQUE_TITLES="MHz_uniqTitles$DATE_ID.txt"
DURATION="$COLS/total_duration$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_CREDITS="$BASELINE/credits.txt"
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
PUBLISHED_MHZ_URLS="$BASELINE/MHz_urls.txt"
PUBLISHED_EPISODE_URLS="$BASELINE/episode_urls.txt"
PUBLISHED_SEASON_URLS="$BASELINE/season_urls.txt"
PUBLISHED_UNIQUE_PERSONS="$BASELINE/uniqPersons.txt"
PUBLISHED_UNIQUE_CHARACTERS="$BASELINE/uniqCharacters.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
PUBLISHED_DURATION="$BASELINE/total_duration.txt"

# Filename groups used for cleanup
ALL_WORKING="$UNSORTED $RAW_CREDITS $RAW_TITLES"
#
ALL_TXT="$EPISODE_URLS $SEASON_URLS $UNIQUE_PERSONS $UNIQUE_CHARACTERS $UNIQUE_TITLES $DURATION"
#
ALL_SPREADSHEETS="$CREDITS $AVG_SPREADSHEET $SHORT_SPREADSHEET $LONG_SPREADSHEET"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS

# Grab only the season and episode URLs from the sitemap
# Unless we already have a result from today
if [ ! -e "$MHZ_URLS" ]; then
    printf "==> Downloading new $MHZ_URLS\n"
    curl -s $SITEMAP_URL | grep '<loc>https://watch.mhzchoice.com.*season:' |
        sed -e 's+^[ \t]*<loc>++;s+</loc>++' -e 's+%2F+/+' | sort -f >$MHZ_URLS
else
    printf "==> using existing $MHZ_URLS\n"
fi

# Separate URLs into seasons and episodes
grep -v 'https://watch.mhzchoice.com.*/season:[0-9]*$' $MHZ_URLS |
    grep -v '/codename-hunter/' >$EPISODE_URLS
grep 'https://watch.mhzchoice.com.*/season:[0-9]*$' $MHZ_URLS |
    grep -v '/codename-hunter/' >$SEASON_URLS
# Special processing for Montalbano which has episodes on page 2
printf "https://watch.mhzchoice.com/detective-montalbano/season:1?page=2\n" >>$SEASON_URLS
printf "https://watch.mhzchoice.com/movie-of-the-week/season:1?page=2\n" >>$SEASON_URLS

# Print header for error file
printf "### Possible anomalies from processing $SITEMAP_URL are listed below.\n\n" >$ERRORS

# Field numbers
# 1 Title  2 Seasons  3 Episodes  4 Duration  5 Genre  6 Country  7 Language  8 Rating  9 Description
#
# Print spreadsheet headers (OK because they will always sort to the top)
printf "Title\tSeasons\tEpisodes\tDuration\tGenre\tCountry\tLanguage\tRating\tDescription\n" \
    >$UNSORTED
printf "Person\tJob\tShow_Type\tShow_Title\tCharacter_Name\n" >$RAW_CREDITS

# loop through the list of URLs from $SEASON_URLS and generate a full but unsorted spreadsheet
while read -r line; do
    curl -sS "$line" |
        awk -v ERRORS=$ERRORS -v RAW_CREDITS=$RAW_CREDITS -v RAW_TITLES=$RAW_TITLES \
            -f getMHzFromSitemap.awk >>$UNSORTED
done <"$SEASON_URLS"

# Create both SHORT_SPREADSHEET and LONG_SPREADSHEET
# Roll up seasons episodes into show episodes, don't print seasons lines
sort -fu --key=4 --field-separator=\" $UNSORTED | sed -n '1!G;h;$p' | awk -v ERRORS=$ERRORS \
    -v DURATION="$DURATION" -v LONG_SPREADSHEET=$LONG_SPREADSHEET -f calculateMHzShowDurations.awk |
    sed -n '1!G;h;$p' >$SHORT_SPREADSHEET
#
awk -f getAvg.awk $SHORT_SPREADSHEET >$AVG_SPREADSHEET
mv $LONG_SPREADSHEET $UNSORTED
sed -n '1!G;h;$p' $UNSORTED >$LONG_SPREADSHEET
rm -f $UNSORTED

# Sort the titles produced by getMHzFromSitemap.awk
sort -fu $RAW_TITLES >$UNIQUE_TITLES
rm -f $RAW_TITLES

# For the shortest runtime, exit here
[ -n "$QUICK" ] && exit

# loop through the list of URLs from $EPISODE_URLS and generate an unsorted credits spreadsheet
while read -r line; do
    curl -sS "$line" |
        awk -v ERRORS=$ERRORS -f getCast.awk >>$RAW_CREDITS
done <"$EPISODE_URLS"

# Generate credits spreadsheets
head -1 $RAW_CREDITS >$CREDITS
# Need sort -fu to get rid of dupes, followed by sort -fb to make Mac/Linux the same
tail -n +2 $RAW_CREDITS | sort -fu | sort -fb >>$CREDITS
tail -n +2 $CREDITS | cut -f 1 | sort -fu >>$UNIQUE_PERSONS
tail -n +2 $CREDITS | cut -f 5 | sort -fu >>$UNIQUE_CHARACTERS
# rm -f $RAW_CREDITS

# Shortcut for printing file info (before adding totals)
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
printAdjustedFileInfo $MHZ_URLS 0
printAdjustedFileInfo $LONG_SPREADSHEET 1
printAdjustedFileInfo $CREDITS 1
printAdjustedFileInfo $EPISODE_URLS 0
printAdjustedFileInfo $UNIQUE_PERSONS 0
printAdjustedFileInfo $UNIQUE_CHARACTERS 0
printAdjustedFileInfo $SEASON_URLS 0
printAdjustedFileInfo $SHORT_SPREADSHEET 1
printAdjustedFileInfo $UNIQUE_TITLES 0

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
    case "$2" in
    sum)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\n" >>$1
        ;;
    total)
        TXT_TOTAL=$(cat $DURATION)
        printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t$TXT_TOTAL\n" >>$1
        ;;
    *)
        printf "==> Bad parameter: addTotalsToSpreadsheet \"$2\" $1\n" >>$ERRORS
        ;;
    esac
}

# Output spreadsheet footer if totals requested
# Either sum or use computed totals from $DURATION
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet $SHORT_SPREADSHEET "total"
    addTotalsToSpreadsheet $LONG_SPREADSHEET "sum"
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
        diff -u "$1" "$2" | diffstat -sq \
            -D $(cd $(dirname "$2") && pwd -P) |
            sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
        # then the diffs
        cmp --quiet "$1" "$2"
        if [ $? == 0 ]; then
            printf "==> no diffs found.\n"
        else
            diff -U 0 "$1" "$2" | awk -f formatUnifiedDiffOutput.awk
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_UNIQUE_PERSONS $UNIQUE_PERSONS)
$(checkdiffs $PUBLISHED_UNIQUE_CHARACTERS $UNIQUE_CHARACTERS)
$(checkdiffs $PUBLISHED_CREDITS $CREDITS)
$(checkdiffs $PUBLISHED_MHZ_URLS $MHZ_URLS)
$(checkdiffs $PUBLISHED_EPISODE_URLS $EPISODE_URLS)
$(checkdiffs $PUBLISHED_SEASON_URLS $SEASON_URLS)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET)
$(checkdiffs $PUBLISHED_DURATION $DURATION)

### Any funny stuff with file lengths?

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit
