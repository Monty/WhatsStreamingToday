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
# Use "-l" switch to include every episode description for each show
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":dlst" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    l)
        INCLUDE_EPISODES="yes"
        echo "NOTICE: The -l option for Acorn TV can take a half hour or more."
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
SEASON_URLS="$COLUMNS/season_urls$DATE_ID.txt"

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
PUBLISHED_SEASON_URLS="$BASELINE/season_urls.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
PUBLISHED_DURATION="$BASELINE/total_duration.txt"

# Filename groups used for cleanup
ALL_WORKING="$UNSORTED $RAW_TITLES $UNIQUE_TITLES $DURATION "
#
ALL_TXT="$SHOW_URLS $EPISODE_URLS $SEASON_URLS "
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET $LONG_SPREADSHEET "

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS

# Print header for possible errors from processing shows
printf "### Possible anomalies from processing shows are listed below.\n\n" >$ERRORS

curl -sS $BROWSE_URL | grep '<a itemprop="url"' | sed -e 's+.*http+http+' -e 's+/">$++' |
    sort -f >$SHOW_URLS
#   head -15 | sort -f >$SHOW_URLS

# keep track of the number of rows in the spreadsheet
lastRow=1

# loop through the list of URLs from $SHOW_URLS and generate a full but unsorted spreadsheet
while read -r line; do
    curl -sS "$line" |
        awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES -f getAcornFrom-showPages.awk >>$UNSORTED
    ((lastRow++))
done <"$SHOW_URLS"

# Sort the titles produced by getAcornFrom-showPages.awk
sort -fu $RAW_TITLES >$UNIQUE_TITLES
rm -f $RAW_TITLES

# Field numbers returned by getAcornFrom-showPages.awk
#     1 Title    2 Seasons   3 Episodes   4 Duration   5 Description
titleCol="1"

# Output $SHORT_SPREADSHEET header
printf "Title\tSeasons\tEpisodes\tDuration\tDescription\n" >$SHORT_SPREADSHEET
# Output $SHORT_SPREADSHEET body
sort --key=4 --field-separator=\" $UNSORTED >> $SHORT_SPREADSHEET
# Output $SHORT_SPREADSHEET footer
if [ "$PRINT_TOTALS" = "yes" ]; then
    TOTAL="Non-blank values\t=COUNTA(B2:B$lastRow)\t=COUNTA(C2:C$lastRow)"
    TOTAL+="\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)"
    printf "$TOTAL\n" >>$SHORT_SPREADSHEET
    printf "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)\t$totalTime\n" \
        >>$SHORT_SPREADSHEET
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
cat >>$POSSIBLE_DIFFS <<EOF2
==> ${0##*/} completed: $(date)

### Any duplicate titles?
$(grep "=HYPERLINK" $SHORT_SPREADSHEET | cut -f $titleCol | uniq -d)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_SHOW_URLS $SHOW_URLS)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET)

### Any funny stuff with file lengths? There should only
### be two different lengths. Any differences in the number
### of lines indicates the website was updated in the
### middle of processing. You should rerun the script!

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF2

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit

if [ "$INCLUDE_EPISODES" = "yes" ]; then
    # Print  header for possible errors from processing episodes
    # Don't delete the blank lines!
    cat >>$ERRORS <<EOF1

### Possible anomalies from processing episodes are listed below.
### At least one episode may have no description, but if there are many,
### there could be a temporary problem with the Acorn website.
### You can check by using your browser to visit the associated URL.
### You should rerun the script when the problem is cleared up.

EOF1

    episodeNumber=1
    # loop through the list of episode URLs from $EPISODE_CURL_FILE
    # WARNING can take an hour or more
    # Generate a separate file with a line for each episode containing
    # the description of that episode
    curl -sS --config $EPISODE_CURL_FILE |
        awk -v EPISODE_DESCRIPTION_FILE=$EPISODE_DESCRIPTION_FILE \
            -v ERRORS=$ERRORS -v EPISODE_CURL_FILE=$EPISODE_CURL_FILE \
            -v EPISODE_NUMBER=$episodeNumber -f getAcornFrom-episodePages.awk
    paste $EPISODE_INFO_FILE $EPISODE_DESCRIPTION_FILE >$EPISODE_PASTED_FILE
    # pick a second file to include in the spreadsheet
    file2=$EPISODE_PASTED_FILE
    ((lastRow += $(sed -n '$=' $file2)))
else
    # null out included file
    file2=""
fi
