#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on OPB TV

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
export DATE_ID="-$(date +%y%m%d)"
export LONGDATE="-$(date +%y%m%d.%H%M%S)"

# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-s" switch to only output a summary. Delete any created files except anomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":ds" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    s)
        SUMMARY="yes"
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

# Make sure network is up and Walter Presents site is reachable
export BROWSE_URL="https://www.pbs.org/franchise/walter-presents/"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    printf "[Error] $BROWSE_URL isn't available, or your network is down.\n"
    printf "        Try accessing $BROWSE_URL in your browser.\n"
    exit 1
fi

# Required subdirectories
COLS="OPB-columns"
BASELINE="OPB-baseline"
mkdir -p $COLS $BASELINE

# File names are used in saveTodaysOPBFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results

# In the default case -- input, output, and baseline files have no date information.
#   but intermediate files have today's date $DATE_ID inserted before the file extension.
# Error and debugging files always have a LONGDATE of the execution time inserted.

# Error and debugging info (per run)
POSSIBLE_DIFFS="OPB_diffs$LONGDATE.txt"
ERRORS="OPB_anomalies$LONGDATE.txt"

# Final output spreadsheets
LONG_SPREADSHEET="OPB_TV_ShowsEpisodes$DATE_ID.csv"

# Basic URL files - all, episodes only, seasons only
EPISODE_IDS="$COLS/episode_ids$DATE_ID.csv"

# Intermediate working files
TMP_DATA="$COLS/tmp_data$DATE_ID.csv"
export AWK_EPISODES="$COLS/awk_episodes$DATE_ID.txt"
LOGFILE="$COLS/logfile_episodes$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
PUBLISHED_EPISODE_IDS="$BASELINE/episode_ids.txt"
PUBLISHED_LOGFILE="$BASELINE/logfile_episodes.txt"

# Filename groups used for cleanup
ALL_WORKING="$LOGFILE $AWK_EPISODES"
#
ALL_TXT="$EPISODE_IDS"
#
ALL_SPREADSHEETS="$LONG_SPREADSHEET"

# Cleanup any possible leftover files
rm -f $ALL_WORKING

# Print header for possible errors from processing shows
printf \
    "### Possible anomalies from processing episodes are listed below.\n\n" \
    >"$ERRORS"

# Print header for $AWK_EPISODES
printf 'BEGIN {\n\tFS = "\\t"\n\tOFS = "\\t"\n}\n\n' >"$AWK_EPISODES"

while read -r line; do
    read -r field1 field2 <<<"$line"
    export TARGET="$field1"
    export AWK_EPISODES=$AWK_EPISODES
    node env-episode.js >>"$LOGFILE"
done <"$EPISODE_IDS"

# Print awk command to print any line not already matched
printf '{ print }\n' >>"$AWK_EPISODES"

mv "$LONG_SPREADSHEET" "$TMP_DATA"
awk -f "$AWK_EPISODES" "$TMP_DATA" >"$LONG_SPREADSHEET"
# rm $TMP_DATA

# Field numbers returned by getWalterFrom-raw_data.awk
#     1 Title     2 Seasons   3 Episodes   4 Duration   5 Genre
#     6 Language  7 Rating    8 Description

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
printf "\n==> Stats from processing episode data:\n"
printAdjustedFileInfo "$LONG_SPREADSHEET" 1
printAdjustedFileInfo "$EPISODE_IDS" 0
printAdjustedFileInfo "$LOGFILE" 0

# Look for any leftover HTML character codes or other problems
probs="$(rg -c --sort path -f rg_problems.rgx $ALL_TXT $ALL_SPREADSHEETS)"
if [ -n "$probs" ]; then
    {
        printf "\n==> Possible formatting problems:\n"
        printf "    $probs\n"
        printf "==> For more details:\n"
        printf "    rg -f rg_problems.rgx OPB_[Tu]*$DATE_ID*\n\n"
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
    printf "    rg -f rg_problems.rgx OPB_[Tu]*$DATE_ID*\n\n"
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
cat >>"$POSSIBLE_DIFFS" <<EOF
==> ${0##*/} completed: $(date)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_EPISODE_IDS "$EPISODE_IDS")
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET "$LONG_SPREADSHEET")
$(checkdiffs $PUBLISHED_LOGFILE "$LOGFILE")

### Any funny stuff with file lengths?

$(wc $ALL_TXT $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_WORKING $ALL_TXT $ALL_SPREADSHEETS
fi

exit
