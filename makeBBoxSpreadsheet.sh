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
SCRAPES="BritBox-scrapes"

mkdir -p $COLUMNS $BASELINE $SCRAPES

# File names are used in saveTodaysBBoxFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results
PROGRAMS_FILE="$SCRAPES/BBoxPrograms.csv"
PROGRAMS_SPREADSHEET_FILE="$COLUMNS/BBoxPrograms-$DATE.csv"
PUBLISHED_PROGRAMS_SPREADSHEET="$BASELINE/BBoxPrograms.txt"
SEASONS_FILE="$SCRAPES/BBoxSeasons.csv"
if [ ! -e "$SEASONS_FILE" ]; then
    SEASONS_FILE="/dev/null"
fi
SEASONS_SPREADSHEET_FILE="$COLUMNS/BBoxSeasons-$DATE.csv"
PUBLISHED_SEASONS_SPREADSHEET="$BASELINE/BBoxSeasons.txt"
EPISODES_FILE="$SCRAPES/BBoxEpisodes.csv"
EPISODES_SPREADSHEET_FILE="$COLUMNS/BBoxEpisodes-$DATE.csv"
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BBoxEpisodes.txt"
DURATION_FILE="$COLUMNS/duration-$DATE.csv"
PUBLISHED_DURATION="$BASELINE/duration.txt"
#
PROGRAMS_SORTED_FILE="$COLUMNS/BBoxPrograms-sorted-$DATE.csv"
EPISODES_SORTED_FILE="$COLUMNS/BBoxEpisodes-sorted-$DATE.csv"
SEASONS_SORTED_FILE="$COLUMNS/BBoxSeasons-sorted-$DATE.csv"
#
PROGRAMS_TITLE_FILE="$COLUMNS/UniqTitle-BBoxPrograms.csv"
EPISODES_TITLE_FILE="$COLUMNS/UniqTitle-BBoxEpisodes$NEWDATE.csv"
# Temporary sorted seasons spreadsheet for debugging
SEASONS_SORTED_SPREADSHEET_FILE="BBoxSeasons-sorted-$DATE.csv"
PUBLISHED_SEASONS_SORTED_SPREADSHEET="$BASELINE/seasons-sorted.txt"
#
SHORT_SPREADSHEET_FILE="BBox_TV_Shows-$DATE.csv"
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet.txt"
LONG_SPREADSHEET_FILE="BBox_TV_ShowsEpisodes-$DATE.csv"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE $PROGRAMS_SPREADSHEET_FILE "
ALL_SPREADSHEETS+="$SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"
#
# Name diffs and errors with both date and time so every run produces a new result
POSSIBLE_DIFFS="BBox_diffs-$LONGDATE.txt"
ERROR_FILE="BBox_anomalies-$LONGDATE.txt"
EPISODE_INFO_FILE="BBox_episodeInfo-$LONGDATE.txt"
#
TEMP_FILE="/tmp/BBoxTemp-$DATE.csv"

# Join broken lines, get rid of useless 'web-scraper-order' field, change comma-separated to
# tab separated, sort into useful order
awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | cut -f 3- -d "," | csvformat -T >$TEMP_FILE
head -1 $TEMP_FILE >$PROGRAMS_SORTED_FILE
grep '/us/' $TEMP_FILE | sort -df --field-separator=$'\t' --key=1,1 \
    >>$PROGRAMS_SORTED_FILE
#
awk -f fixExtraLinesFrom-webscraper.awk $EPISODES_FILE | cut -f 2- -d "," | csvformat -T >$TEMP_FILE
head -1 $TEMP_FILE >$EPISODES_SORTED_FILE
grep '/us/' $TEMP_FILE | sort -df --field-separator=$'\t' --key=1,1 --key=8,8 --key=5,5 \
    >>$EPISODES_SORTED_FILE
#
awk -f fixExtraLinesFrom-webscraper.awk $SEASONS_FILE | cut -f 2- -d "," | csvformat -T >$TEMP_FILE
head -1 $TEMP_FILE >$SEASONS_SORTED_FILE
grep '/us/' $TEMP_FILE | sort -df --field-separator=$'\t' --key=1,1 --key=9,9 --key=4,4 |
    grep -v /us/episode/ >>$SEASONS_SORTED_FILE
#
rm -f $TEMP_FILE

# Print header for verifying episodes across webscraper downloads
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE
#
# Print header for possible missing episode errors
printf "### Program Titles not found in $EPISODES_SORTED_FILE are listed below.\n\n" >$ERROR_FILE

grep '/us/' $PROGRAMS_SORTED_FILE | cut -f 2 -d $'\t' | sort -u >$PROGRAMS_TITLE_FILE
grep '/us/' $EPISODES_SORTED_FILE | cut -f 5 -d $'\t' | sort -u >$EPISODES_TITLE_FILE

comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -e 's/^/    /' >>$ERROR_FILE
missingTitles=$(comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -n '$=')
echo "==> $missingTitles Program titles not found in $EPISODES_SORTED_FILE" >&2

# Print header for possible errors that occur during processing
printf "\n### /program/ URLs not found in $EPISODES_SORTED_FILE are listed below.\n\n" >>$ERROR_FILE

rm -f $TEMP_FILE
awk -v EPISODES_SORTED_FILE=$EPISODES_SORTED_FILE -v SEASONS_SORTED_FILE=$SEASONS_SORTED_FILE \
    -v TEMP_FILE=$TEMP_FILE -f verifyBBoxDownloadsFrom-webscraper.awk $PROGRAMS_SORTED_FILE \
    >>$EPISODE_INFO_FILE
sort -df $TEMP_FILE >>$ERROR_FILE
echo "" >>$ERROR_FILE

rm -f $DURATION_FILE $SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE \
    $PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE

# Add header about info obtained during processing of shows
printf "\n\n### Information from processing shows is listed below.\n\n" >>$EPISODE_INFO_FILE
#
# Add header for possible errors that occur during processing
printf "### /show/ URLs that shouldn't be in $PROGRAMS_SORTED_FILE are listed below.\n\n" >>$ERROR_FILE

# Generate _initial_ spreadsheets from BritBox "Programmes A-Z" page
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxProgramsFrom-webscraper.awk $PROGRAMS_SORTED_FILE >$PROGRAMS_SPREADSHEET_FILE
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxEpisodesFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE

exit

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=4,4 |
    awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
        -f getBBoxProgramsFrom-webscraper.awk >$PROGRAMS_SPREADSHEET_FILE
grep -v '"null","","","",' $SEASONS_FILE | awk -f fixExtraLinesFrom-webscraper.awk |
    csvformat -T | grep "^1" | sort -df --field-separator=$'\t' --key=9,9 --key=6,6 |
    awk -v ERROR_FILE=$ERROR_FILE -f getBBoxSeasonsFrom-webscraper.awk >$SEASONS_SPREADSHEET_FILE

# Temporarily save a sorted "seasons file" for easier debugging.
# Don't sort header line, keep it at the top of the spreadsheet
head -1 $SEASONS_SPREADSHEET_FILE >$SEASONS_SORTED_SPREADSHEET_FILE
grep -hv ^Sortkey $SEASONS_SPREADSHEET_FILE | sort -f >>$SEASONS_SORTED_SPREADSHEET_FILE

# Generate _final_ spreadsheets from BritBox "Programmes A-Z" page
head -1 $PROGRAMS_SPREADSHEET_FILE >$LONG_SPREADSHEET_FILE
grep -hv ^Sortkey $PROGRAMS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE | sort -f |
    tail -r | awk -v ERROR_FILE=$ERROR_FILE -v DURATION_FILE=$DURATION_FILE \
        -f calculateBBoxDurations.awk | tail -r >>$LONG_SPREADSHEET_FILE
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
