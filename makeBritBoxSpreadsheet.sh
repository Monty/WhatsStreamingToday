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
PROGRAMS_FILE="$COLUMNS/BritBoxPrograms.csv"
PROGRAMS_SPREADSHEET_FILE="$COLUMNS/BritBoxPrograms-$DATE.csv"
PUBLISHED_PROGRAMS_SPREADSHEET="$BASELINE/BritBoxPrograms.txt"
SEASONS_FILE="$COLUMNS/BritBoxSeasons.csv"
SEASONS_SPREADSHEET_FILE="$COLUMNS/BritBoxSeasons-$DATE.csv"
PUBLISHED_SEASONS_SPREADSHEET="$BASELINE/BritBoxSeasons.txt"
EPISODES_FILE="$COLUMNS/BritBoxEpisodes.csv"
EPISODES_SPREADSHEET_FILE="$COLUMNS/BritBoxEpisodes-$DATE.csv"
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BritBoxEpisodes.txt"
# Temporarily create a sorted seasons spreadsheet for debugging
SEASONS_SORTED_SPREADSHEET_FILE="BritBoxSeasons-sorted-$DATE.csv"
PUBLISHED_SEASONS_SORTED_SPREADSHEET="$BASELINE/seasons-sorted.txt"
# Probably obsolete
DURATION_FILE="$COLUMNS/durations-$DATE.csv"
PUBLISHED_DURATIONS="$BASELINE/durations.txt"
#
if [ "$INCLUDE_EPISODES" = "yes" ]; then
    SPREADSHEET_FILE="BritBox_TV_ShowsEpisodes-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
    # pick a second file to include in the spreadsheet
    file2="$EPISODES_SPREADSHEET_FILE"
else
    SPREADSHEET_FILE="BritBox_TV_Shows-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
    # null out included file
    file2=""
fi
#
# Name diffs and errors with both date and time so every run produces a new result
POSSIBLE_DIFFS="BritBox_diffs-$LONGDATE.txt"
ERROR_FILE="BritBox_anomalies-$LONGDATE.txt"
#
ALL_SPREADSHEETS="$SPREADSHEET_FILE $PROGRAMS_SPREADSHEET_FILE "
ALL_SPREADSHEETS+="$SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"

rm -f $DURATION_FILE $SPREADSHEET_FILE \
    $PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE

# Generate _initial_ spreadsheets from BritBox "Programmes A-Z" page
awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=4,4 |
    awk -f getBritBoxProgramsFrom-webscraper.awk >$PROGRAMS_SPREADSHEET_FILE
grep -v '"null","","","",' $SEASONS_FILE | awk -f fixExtraLinesFrom-webscraper.awk |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=9,9 --key=6,6 |
    awk -f getBritBoxSeasonsFrom-webscraper.awk >$SEASONS_SPREADSHEET_FILE
awk -f fixExtraLinesFrom-webscraper.awk $EPISODES_FILE |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=8,8 --key=7,7 |
    awk -f getBritBoxEpisodesFrom-webscraper.awk >$EPISODES_SPREADSHEET_FILE

# Generate _final_ spreadsheets from BritBox "Programmes A-Z" page
head -1 $PROGRAMS_SPREADSHEET_FILE >$SPREADSHEET_FILE
grep -hv ^Sortkey $PROGRAMS_SPREADSHEET_FILE $file2 | sort -f >>$SPREADSHEET_FILE
#
head -1 $SEASONS_SPREADSHEET_FILE >$SEASONS_SORTED_SPREADSHEET_FILE
grep -hv ^Sortkey $SEASONS_SPREADSHEET_FILE | sort -f >>$SEASONS_SORTED_SPREADSHEET_FILE

# Total the duration of all episodes in every series
# totalTime=$(awk -v DURATION_FILE=$DURATION_FILE -f calculateDurations.awk $EPISODE_INFO_FILE)

# Output spreadsheet footer if totals requested
if [ "$PRINT_TOTALS" = "yes" ]; then
    ((lastRow = $(sed -n '$=' $SPREADSHEET_FILE)))
    TOTAL="\tNon-blank values\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)"
    TOTAL+="\t=COUNTA(F2:F$lastRow)\t=COUNTA(G2:G$lastRow)\t=COUNTA(H2:H$lastRow)"
    printf "$TOTAL\n" >>$SPREADSHEET_FILE
    printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\n" \
        >>$SPREADSHEET_FILE
fi

#
# Print header then possible errors from processing initial series
printf "### Possible anomalies from processing shows are listed below.\n\n" >$ERROR_FILE

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

fi

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_PROGRAMS_SPREADSHEET $PROGRAMS_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SEASONS_SPREADSHEET $SEASONS_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_EPISODES_SPREADSHEET $EPISODES_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SEASONS_SORTED_SPREADSHEET $SEASONS_SORTED_SPREADSHEET_FILE)

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
