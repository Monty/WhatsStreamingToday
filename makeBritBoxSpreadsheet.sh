#! /bin/bash
# Create a .csv spreadsheet of shows available on BritBox

# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-l" switch to include every episode description for each series
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
# Use "-u" switch to leave spreadsheet unsorted, i.e. in the order found on the web
while getopts ":dltu" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    l)
        INCLUDE_EPISODES="yes"
        ;;
    t)
        PRINT_TOTALS="yes"
        ;;
    u)
        UNSORTED="yes"
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

# Make sure network is up and BritBox site is reachable
BROWSE_URL="https://www.britbox.com/us/programmes"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    echo "[Error] $BROWSE_URL isn't available, or your network is down."
    echo "        Try accessing $BROWSE_URL in your browser"
    exit 1
fi

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

COLUMNS="BritBox-columns"
BASELINE="BritBox-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveTodaysBritBoxFiles.sh
# so if you change them here, change them there as well
# they are named with today's date so running them twice
# in one day will only generate one set of results
PROGRAMS_SPREADSHEET_FILE="$COLUMNS/BritBoxPrograms-$DATE.csv"
SEASONS_SPREADSHEET_FILE="$COLUMNS/BritBoxSeasons-$DATE.csv"
EPISODES_SPREADSHEET_FILE="$COLUMNS/BritBoxEpisodes-$DATE.csv"
PROGRAMS_FILE="$COLUMNS/BritBoxPrograms.csv"
SEASONS_FILE="$COLUMNS/BritBoxSeasons.csv"
EPISODES_FILE="$COLUMNS/BritBoxEpisodes.csv"
# Probably obsolete
DESCRIPTION_FILE="$COLUMNS/descriptions-$DATE.csv"
PUBLISHED_DESCRIPTIONS="$BASELINE/descriptions.txt"
DURATION_FILE="$COLUMNS/durations-$DATE.csv"
PUBLISHED_DURATIONS="$BASELINE/durations.txt"
HEADER_FILE="$COLUMNS/headers-$DATE.csv"
PUBLISHED_HEADERS="$BASELINE/headers.txt"
EPISODE_INFO_FILE="$COLUMNS/episodeInfo-$DATE.csv"
PUBLISHED_EPISODE_INFO="$BASELINE/episodeInfo.txt"
#
if [ "$INCLUDE_EPISODES" = "yes" ]; then
    SPREADSHEET_FILE="BritBox_TV_ShowsEpisodes-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
else
    SPREADSHEET_FILE="BritBox_TV_Shows-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
fi
#
# Name diffs and errors with both date and time so every run produces a new result
POSSIBLE_DIFFS="BritBox_diffs-$LONGDATE.txt"
ERROR_FILE="BritBox_stderr-$LONGDATE.txt"

rm -f $DESCRIPTION_FILE $DURATION_FILE $HEADER_FILE $EPISODE_INFO_FILE \
    $SPREADSHEET_FILE $PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE

# Generate spreadsheets from BritBox "Programmes A-Z" page
csvformat -T $PROGRAMS_FILE | grep "^1" | sort -df --field-separator=$'\t' --key=4,4 |
    awk -f getBritBoxProgramsFrom-webscraper.awk >$PROGRAMS_SPREADSHEET_FILE
csvformat -T $SEASONS_FILE | grep "^1" | sort -df --field-separator=$'\t' --key=9,9 --key=6,6 |
    awk -f getBritBoxSeasonsFrom-webscraper.awk >$SEASONS_SPREADSHEET_FILE
csvformat -T $EPISODES_FILE | grep "^1" | sort -df --field-separator=$'\t' --key=8,8 --key=7,7 |
    awk -f getBritBoxEpisodesFrom-webscraper.awk >$EPISODES_SPREADSHEET_FILE

exit

# Print header for possible errors from processing series
printf "### Possible anomalies from processing series are listed below.\n\n" >$ERROR_FILE

# Total the duration of all episodes in every series
totalTime=$(awk -v DURATION_FILE=$DURATION_FILE -f calculateDurations.awk $EPISODE_INFO_FILE)

#
# Output body
if [ "$INCLUDE_EPISODES" = "yes" ]; then
    # Print  header for possible errors from processing episodes
    # Don't delete the blank lines!
    cat >>$ERROR_FILE <<EOF1

### Possible anomalies from processing episodes are listed below.
### At least one episode may have no description, but if there are many,
### there could be a temporary problem with the BritBox website.
### You can check by using your browser to visit the associated URL.
### You should rerun the script when the problem is cleared up.

EOF1

    # pick a second file to include in the spreadsheet
    file2=$EPISODE_INFO_FILE
    ((lastRow += $(sed -n '$=' $file2)))
else
    # null out included file
    file2=""
fi
#
if [ "$UNSORTED" = "yes" ]; then
    # sort key 1 sorts in the order found on the web
    # sort key 4 sorts by title
    # both sort $file2 by season then episode (if one is provided)
    paste $DURATION_FILE $HEADER_FILE \
        $DESCRIPTION_FILE | awk '{print NR"\t"$0}' | cat - $file2 |
        sort --key=1,1n --key=4 --field-separator=\" >>$SPREADSHEET_FILE
else
    paste $DURATION_FILE $HEADER_FILE \
        $DESCRIPTION_FILE | awk '{print NR"\t"$0}' | cat - $file2 |
        sort --key=4 --field-separator=\" >>$SPREADSHEET_FILE
fi
#
# Output footer
if [ "$PRINT_TOTALS" = "yes" ]; then
    TOTAL="\tNon-blank values\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)"
    TOTAL+="\t=COUNTA(F2:F$lastRow)\t=COUNTA(G2:G$lastRow)\t=COUNTA(H2:H$lastRow)"
    TOTAL+="\t=COUNTA(I2:I$lastRow)\t=COUNTA(J2:J$lastRow)"
    printf "$TOTAL\n" >>$SPREADSHEET_FILE
    printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t$totalTime\n" \
        >>$SPREADSHEET_FILE
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    exit
fi

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs() {
    echo
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


### MHz shows on the web are not sorted by title. When shows are
### rearranged, the individual column diffs may look significant.
### Check the "titles" column diffs to see if the changes are only
### from identical titles being deleted and re-inserted.
$(checkdiffs $PUBLISHED_DURATIONS $DURATION_FILE)


### Any funny stuff with file lengths? Any differences in
### number of lines indicates the website was updated in the
### middle of processing. You should rerun the script!

$(wc $COLUMNS/*$DATE.csv)

EOF

echo
echo "==> ${0##*/} completed: $(date)"
