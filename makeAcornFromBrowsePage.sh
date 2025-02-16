#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on Acorn TV
#
# shellcheck disable=SC2317

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
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    esac
done

# Make sure we can execute curl.
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    printf "[Error] Can't run curl. Install curl and rerun this script.\n"
    printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
    exit 1
fi

# Make sure network is up and the Acorn TV site is reachable
BROWSE_URL="https://acorn.tv/browse/all"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    printf "[Error] $BROWSE_URL isn't available, or your network is down.\n"
    printf "        Try accessing $BROWSE_URL in your browser.\n"
    exit 1
fi

# Required subdirectories
COLS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLS $BASELINE

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
SHOW_URLS="$COLS/show_urls$DATE_ID.txt"
EPISODE_URLS="$COLS/episode_urls$DATE_ID.txt"

# Intermediate working files
UNSORTED="$COLS/unsorted$DATE_ID.txt"
RAW_TITLES="$COLS/rawTitles$DATE_ID.txt"
UNIQUE_TITLES="Acorn_uniqTitles$DATE_ID.txt"
DURATION="$COLS/total_duration$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
PUBLISHED_SHOW_URLS="$BASELINE/show_urls.txt"
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
# shellcheck disable=SC2086
rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS

if [ ! -e "$SHOW_URLS" ]; then
    printf "==> Downloading new $SHOW_URLS\n"
    curl -sS $BROWSE_URL | grep '<a itemprop="url"' |
        sed -e 's+.*http+http+' -e 's+/">$++' |
        sort -f >"$SHOW_URLS"
else
    printf "==> using existing $SHOW_URLS\n"
fi

# Print header for possible errors from processing shows
printf "\n### Possible anomalies from processing shows are listed below.\n\n" >"$ERRORS"

# loop through the list of URLs from $SHOW_URLS and generate a full but unsorted spreadsheet
sed -e 's+^+url = "+' -e 's+$+"+' "$SHOW_URLS" | curl -sS --config - |
    awk -v ERRORS="$ERRORS" -v RAW_TITLES="$RAW_TITLES" -v EPISODE_URLS="$EPISODE_URLS" \
        -v DURATION="$DURATION" -v SHORT_SPREADSHEET="$SHORT_SPREADSHEET" \
        -f getAcornFrom-showPages.awk >"$UNSORTED"

# Field numbers returned by getAcornFrom-showPages.awk
#     1 Title    2 Seasons   3 Episodes   4 Duration   5 Description
titleCol="1"

# Print header for $LONG_SPREADSHEET
printf "Title\tSeasons\tEpisodes\tDuration\tDescription\n" >"$LONG_SPREADSHEET"
# Create $LONG_SPREADSHEET sorted by title, not URL
sort -fu --key=4 --field-separator=\" "$UNSORTED" >>"$LONG_SPREADSHEET"
rm -f "$UNSORTED"

# Generate $SHORT_SPREADSHEET
mv "$SHORT_SPREADSHEET" "$UNSORTED"
# Output $SHORT_SPREADSHEET header
printf "Title\tSeasons\tEpisodes\tDuration\tDescription\n" >"$SHORT_SPREADSHEET"
# Output $SHORT_SPREADSHEET body sorted by title, not URL
sort -fu --key=4 --field-separator=\" "$UNSORTED" >>"$SHORT_SPREADSHEET"
rm -f "$UNSORTED"

# Sort the titles produced by getAcornFrom-showPages.awk
sort -fu "$RAW_TITLES" >"$UNIQUE_TITLES"
rm -f "$RAW_TITLES"
# Sort episode URLs produced by getAcornFrom-showPages.awk
mv "$EPISODE_URLS" "$UNSORTED"
sort -fu "$UNSORTED" >"$EPISODE_URLS"
rm -f "$UNSORTED"

# Shortcut for printing file info (before adding totals)
function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    numlines=$(($(sed -n '$=' "$1") - $2))
    ls -loh "$1" |
        awk -v nl=$numlines '{ printf ("%-45s%6s%6s %s %s %8d lines\n", $8, $4, $5, $6, $7, nl); }'
}

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from downloading and processing raw sitemap data:\n"
printAdjustedFileInfo "$LONG_SPREADSHEET" 1
printAdjustedFileInfo "$EPISODE_URLS" 0
printAdjustedFileInfo "$SHOW_URLS" 0
printAdjustedFileInfo "$SHORT_SPREADSHEET" 1
printAdjustedFileInfo "$UNIQUE_TITLES" 0

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
# Either sum or use computed totals from $DURATION
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet "$SHORT_SPREADSHEET" "total"
    addTotalsToSpreadsheet "$LONG_SPREADSHEET" "sum"
fi

# Look for any leftover HTML character codes or other problems
# shellcheck disable=SC2086
probs="$(rg -c --sort path -f rg_problems.rgx $ALL_TXT $ALL_SPREADSHEETS)"
if [ -n "$probs" ]; then
    {
        printf "\n==> Possible formatting problems:\n"
        printf "    $probs\n"
        printf "==> For more details:\n"
        printf "    rg -f rg_problems.rgx Acorn_[Tu]*$DATE_ID*\n\n"
    } >>"$ERRORS"
fi
#
# Also send to stdout
# shellcheck disable=SC2086
probs="$(rg -c --color ansi --sort path -f rg_problems.rgx \
    $ALL_TXT $ALL_SPREADSHEETS)"
if [ -n "$probs" ]; then
    printf "\n==> Possible formatting problems:\n"
    printf "    $probs\n"
    printf "==> For more details:\n"
    printf "    rg -f rg_problems.rgx Acorn_[Tu]*$DATE_ID*\n\n"
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        # shellcheck disable=SC2086
        rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
    fi
    exit
fi

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
            printf "==> no diffs found.\n"
        else
            diff -U 0 "$1" "$2" | awk -f formatUnifiedDiffOutput.awk
        fi
    fi
}

# Preserve any possible errors for debugging
# shellcheck disable=SC2086
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Any duplicate titles?
$(grep "=HYPERLINK" $SHORT_SPREADSHEET | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_SHOW_URLS $SHOW_URLS)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET)
$(checkdiffs $PUBLISHED_DURATION $DURATION)
$(checkdiffs $PUBLISHED_EPISODE_URLS $EPISODE_URLS)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET)

### Any funny stuff with file lengths?

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    # shellcheck disable=SC2086
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit
