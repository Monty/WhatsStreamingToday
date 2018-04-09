#! /bin/bash
# Create a .csv spreadsheet of shows available on BritBox

# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":dt" opt; do
    case $opt in
    d)
        DEBUG="yes"
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
PROGRAMS_FILE="$COLUMNS/BritBoxPrograms.csv"
PROGRAMS_SPREADSHEET_FILE="$COLUMNS/BritBoxPrograms-$DATE.csv"
PUBLISHED_PROGRAMS_SPREADSHEET="$BASELINE/BritBoxPrograms.txt"
SEASONS_FILE="$COLUMNS/BritBoxSeasons.csv"
SEASONS_SPREADSHEET_FILE="$COLUMNS/BritBoxSeasons-$DATE.csv"
PUBLISHED_SEASONS_SPREADSHEET="$BASELINE/BritBoxSeasons.txt"
EPISODES_FILE="$COLUMNS/BritBoxEpisodes.csv"
EPISODES_SPREADSHEET_FILE="$COLUMNS/BritBoxEpisodes-$DATE.csv"
EPISODE_INFO_FILE="$COLUMNS/episodeInfo-$DATE.txt"
PUBLISHED_EPISODE_INFO="$BASELINE/episodeInfo.txt"
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BritBoxEpisodes.txt"
DURATION_FILE="$COLUMNS/duration-$DATE.csv"
PUBLISHED_DURATION="$BASELINE/duration.txt"
# Temporarily create a sorted seasons spreadsheet for debugging
SEASONS_SORTED_SPREADSHEET_FILE="BritBoxSeasons-sorted-$DATE.csv"
PUBLISHED_SEASONS_SORTED_SPREADSHEET="$BASELINE/seasons-sorted.txt"
#
SHORT_SPREADSHEET_FILE="BritBox_TV_Shows-$DATE.csv"
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
LONG_SPREADSHEET_FILE="BritBox_TV_ShowsEpisodes-$DATE.csv"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE $PROGRAMS_SPREADSHEET_FILE "
ALL_SPREADSHEETS+="$SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"
#
# Name diffs and errors with both date and time so every run produces a new result
POSSIBLE_DIFFS="BritBox_diffs-$LONGDATE.txt"
ERROR_FILE="BritBox_anomalies-$LONGDATE.txt"

# Print header for used for verifying episodes across webscraper downloads
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE

# Print header for possible errors that occur during processing
printf "### Possible anomalies from processing shows are listed below.\n\n" >$ERROR_FILE

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | sort -df --field-separator=$',' --key=3 |
    awk -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE \
    -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f verifyBritBoxDownloadsFrom-webscraper.awk

rm -f $DURATION_FILE $SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE \
    $PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE

# Generate _initial_ spreadsheets from BritBox "Programmes A-Z" page
awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=4,4 |
    awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBritBoxProgramsFrom-webscraper.awk >$PROGRAMS_SPREADSHEET_FILE
grep -v '"null","","","",' $SEASONS_FILE | awk -f fixExtraLinesFrom-webscraper.awk |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=9,9 --key=6,6 |
    awk -v ERROR_FILE=$ERROR_FILE -f getBritBoxSeasonsFrom-webscraper.awk >$SEASONS_SPREADSHEET_FILE
awk -f fixExtraLinesFrom-webscraper.awk $EPISODES_FILE |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=8,8 --key=7,7 |
    awk -v ERROR_FILE=$ERROR_FILE -f getBritBoxEpisodesFrom-webscraper.awk >$EPISODES_SPREADSHEET_FILE
# Temporarily save a sorted "seasons file" for easier debugging.
# Don't sort header line, keep it at the top of the spreadsheet
head -1 $SEASONS_SPREADSHEET_FILE >$SEASONS_SORTED_SPREADSHEET_FILE
grep -hv ^Sortkey $SEASONS_SPREADSHEET_FILE | sort -f >>$SEASONS_SORTED_SPREADSHEET_FILE

# Generate _final_ spreadsheets from BritBox "Programmes A-Z" page
head -1 $PROGRAMS_SPREADSHEET_FILE >$LONG_SPREADSHEET_FILE
grep -hv ^Sortkey $PROGRAMS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE | sort -f |
    tail -r | awk -v ERROR_FILE=$ERROR_FILE -v DURATION_FILE=$DURATION_FILE \
        -f calculateBritBoxDurations.awk | tail -r >>$LONG_SPREADSHEET_FILE
#
grep -v ' (2) ' $LONG_SPREADSHEET_FILE >$SHORT_SPREADSHEET_FILE

# Shortcut for adding totals to spreadsheets
function addTotalsToSpreadsheet() {
    # Grab (the last) totalTime (just in case)
    totalTime=$(grep : $DURATION_FILE | tail -1)
    ((lastRow = $(sed -n '$=' $1)))
    TOTAL="\tNon-blank values\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)"
    TOTAL+="\t=COUNTA(F2:F$lastRow)\t=COUNTA(G2:G$lastRow)\t=COUNTA(H2:H$lastRow)"
    printf "$TOTAL\n" >>$1
    printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t$totalTime\n" \
        >>$1
}

# Output spreadsheet footer if totals requested
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet $SHORT_SPREADSHEET_FILE
    addTotalsToSpreadsheet $LONG_SPREADSHEET_FILE
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
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

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_PROGRAMS_SPREADSHEET $PROGRAMS_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SEASONS_SPREADSHEET $SEASONS_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_EPISODES_SPREADSHEET $EPISODES_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SEASONS_SORTED_SPREADSHEET $SEASONS_SORTED_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_DURATION $DURATION_FILE)

### These counts should not vary much over time
### if they do, the earlier scraping operation may have failed

==> Number of Movies
$(countOccurrences "/us/movie/")

==> Number of Shows
$(countOccurrences "/us/show/")

==> Number of Episodes
$(countOccurrences "/us/episode/")

### Any funny stuff with file lengths?

$(wc $ALL_SPREADSHEETS)

EOF

echo
echo "==> ${0##*/} completed: $(date)"
