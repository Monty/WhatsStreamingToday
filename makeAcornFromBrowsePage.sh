#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on Acorn TV

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
        echo "Ignoring invalid option: -$OPTARG" >&2
        ;;
    esac
done

# Make sure we can execute curl.
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    echo "[Error] Can't run curl. Install curl and rerun this script."
    echo "        To test, type:  curl -Is https://github.com/ | head -5"
    exit 1
fi

# Make sure network is up and the Acorn TV site is reachable
BROWSE_URL="https://acorn.tv/browse/all"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    echo "[Error] $BROWSE_URL isn't available, or your network is down."
    echo "        Try accessing $BROWSE_URL in your browser"
    exit 1
fi

# Required subdirectories
COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveTodaysAcornFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results

# In the default case -- input, output, and baseline files have no date information.
#   but intermediate files have today's date $DATE_ID inserted before the file extension.
# Error and debugging files always have a LONGDATE of the execution time inserted.

# Error and debugging info (per run)
POSSIBLE_DIFFS="Acorn_diffs$LONGDATE.txt"
ERRORS="Acorn_anomalies$LONGDATE.txt"

# Final output spreadsheets
SHORT_SPREADSHEET="Acorn_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET="Acorn_TV_ShowsEpisodes$DATE_ID.csv"

# Basic URL files - all, episodes only, seasons only
SHOW_URLS="$COLUMNS/show_urls$DATE_ID.txt"
EPISODE_URLS="$COLUMNS/episode_urls$DATE_ID.txt"

# Intermediate working files
UNSORTED="$COLUMNS/unsorted$DATE_ID.txt"
RAW_TITLES="$COLUMNS/rawTitles$DATE_ID.txt"
UNIQUE_TITLES="$COLUMNS/uniqTitles$DATE_ID.txt"
DURATION="$COLUMNS/total_duration$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
PUBLISHED_SHOW_URLS="$COLUMNS/show_urls$DATE_ID.txt"
PUBLISHED_EPISODE_URLS="$BASELINE/episode_urls.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
PUBLISHED_DURATION="$BASELINE/total_duration.txt"

# Filename groups used for cleanup
ALL_WORKING="$UNSORTED $RAW_TITLES $DURATION"
#
ALL_TXT="$UNIQUE_TITLES $SHOW_URLS $EPISODE_URLS"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET $LONG_SPREADSHEET"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS

curl -sS $BROWSE_URL | grep '<a itemprop="url"' | sed -e 's+.*http+http+' -e 's+/">$++' |
    sort -f >$SHOW_URLS

# Print header for possible errors from processing shows
printf "\n### Possible anomalies from processing shows are listed below.\n\n" >$ERRORS

# keep track of the number of rows in the spreadsheet
lastRow=1

# loop through the list of URLs from $SHOW_URLS and generate a full but unsorted spreadsheet
sed -e 's+^+url = "+' -e 's+$+"+' $SHOW_URLS | curl -sS --config - |
    awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES -v EPISODE_URLS=$EPISODE_URLS \
        -v DURATION=$DURATION -v SHORT_SPREADSHEET=$SHORT_SPREADSHEET \
        -f getAcornFrom-showPages.awk >$UNSORTED

# Field numbers returned by getAcornFrom-showPages.awk
#     1 Title    2 Seasons   3 Episodes   4 Duration   5 Description
titleCol="1"

# Print header for $LONG_SPREADSHEET
printf "Title\tSeasons\tEpisodes\tDuration\tDescription\n" >$LONG_SPREADSHEET
# Create $LONG_SPREADSHEET sorted by title, not URL
sort -fu --key=4 --field-separator=\" $UNSORTED >>$LONG_SPREADSHEET
rm -f $UNSORTED

# Generate $SHORT_SPREADSHEET
mv $SHORT_SPREADSHEET $UNSORTED
# Output $SHORT_SPREADSHEET header
printf "Title\tSeasons\tEpisodes\tDuration\tDescription\n" >$SHORT_SPREADSHEET
# Output $SHORT_SPREADSHEET body sorted by title, not URL
sort -fu --key=4 --field-separator=\" $UNSORTED >>$SHORT_SPREADSHEET
rm -f $UNSORTED

# Sort the titles produced by getAcornFrom-showPages.awk
sort -fu $RAW_TITLES >$UNIQUE_TITLES
rm -f $RAW_TITLES
# Sort episode URLs produced by getAcornFrom-showPages.awk
mv $EPISODE_URLS $UNSORTED
sort -fu $UNSORTED >$EPISODE_URLS
rm -f $UNSORTED

# Shortcut for printing file info (before adding totals)
function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    filesize=$(ls -loh $1 | cut -c 22-26)
    filedate=$(ls -loh $1 | cut -c 28-39)
    numlines=$(($(sed -n '$=' $1) - $2))
    printf "%-45s%6s%15s%9d lines\n" "$1" "$filesize" "$filedate" "$numlines"
}

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from downloading and processing raw sitemap data:\n"
printAdjustedFileInfo $LONG_SPREADSHEET 1
printAdjustedFileInfo $EPISODE_URLS 0
printAdjustedFileInfo $SHOW_URLS 0
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
    #
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

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs() {
    echo
    if [ ! -e "$2" ]; then
        echo "==> $2 does not exist. Skipping diff."
        return 1
    fi
    if [ ! -e "$1" ]; then
        # If the basefile file doesn't yet exist, assume no differences
        # and copy the newfile to the basefile so it can serve
        # as a base for diffs in the future.
        echo "==> $1 does not exist. Creating it, assuming no diffs."
        cp -p "$2" "$1"
    else
        echo "==> what changed between $1 and $2:"
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
            echo "==> no diffs found"
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Any duplicate titles?
$(grep "=HYPERLINK" $SHORT_SPREADSHEET | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_DURATION $DURATION)
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_SHOW_URLS $SHOW_URLS)
$(checkdiffs $PUBLISHED_EPISODE_URLS $EPISODE_URLS)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET)

### Any funny stuff with file lengths?

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit
