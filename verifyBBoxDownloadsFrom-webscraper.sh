#! /bin/bash

# Check that the current downloads from WebScraper are in sync with each other
# -d DATE picks a different date

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

# Allow user to override DATE
while getopts ":d:v" opt; do
    case $opt in
    d)
        NEWDATE="-$OPTARG"
        ;;
    v)
        VERBOSE="-v"
        ;;
    \?)
        echo "Ignoring invalid option: -$OPTARG" >&2
        ;;
    :)
        echo "Option -$OPTARG requires a 'date' argument such as $LONGDATE" >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# Pick files to be used
SCRAPES="BritBox-scrapes"
COLUMNS="$SCRAPES/columns"
#
PROGRAMS_FILE="$SCRAPES/BBoxPrograms.csv"
EPISODES_FILE="$SCRAPES/BBoxEpisodes$NEWDATE.csv"
SEASONS_FILE="$SCRAPES/BBoxSeasons$NEWDATE.csv"
#
PROGRAMS_SORTED_FILE="$SCRAPES/BBoxPrograms-sorted$NEWDATE.csv"
EPISODES_SORTED_FILE="$SCRAPES/BBoxEpisodes-sorted$NEWDATE.csv"
SEASONS_SORTED_FILE="$SCRAPES/BBoxSeasons-sorted$NEWDATE.csv"
#
PROGRAMS_TITLE_FILE="$COLUMNS/UniqTitle-BBoxPrograms.csv"
EPISODES_TITLE_FILE="$COLUMNS/UniqTitle-BBoxEpisodes$NEWDATE.csv"
#
EPISODE_INFO_FILE="checkEpisodeInfo-$LONGDATE.txt"
ERROR_FILE="checkBBox_anomalies-$LONGDATE.txt"
#
TEMP_FILE="/tmp/BBoxTemp$NEWDATE.csv"
#
mkdir -p $SCRAPES $COLUMNS

# Make sure we can use >> to create first line of ERROR_FILE
rm -f $ERROR_FILE

# Record which files were processed
if [ "$VERBOSE" != "" ]; then
    echo "### Files processed include:" >>$ERROR_FILE
    echo "" >>$ERROR_FILE
    echo "    PROGRAMS_FILE = $PROGRAMS_FILE" >>$ERROR_FILE
    echo "    EPISODES_FILE = $EPISODES_FILE" >>$ERROR_FILE
    echo "    SEASONS_FILE = $SEASONS_FILE" >>$ERROR_FILE
    echo "" >>$ERROR_FILE
    echo "    PROGRAMS_SORTED_FILE = $PROGRAMS_SORTED_FILE" >>$ERROR_FILE
    echo "    EPISODES_SORTED_FILE = $EPISODES_SORTED_FILE" >>$ERROR_FILE
    echo "    SEASONS_SORTED_FILE = $SEASONS_SORTED_FILE" >>$ERROR_FILE
    echo "" >>$ERROR_FILE
    echo "    PROGRAMS_TITLE_FILE = " $PROGRAMS_TITLE_FILE >>$ERROR_FILE
    echo "    EPISODES_TITLE_FILE = " $EPISODES_TITLE_FILE >>$ERROR_FILE
    echo "" >>$ERROR_FILE
fi

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

# Print header for possible errors that occur during processing
printf "### Program Titles not found in $EPISODES_SORTED_FILE are listed below.\n\n" >>$ERROR_FILE

grep '/us/' $PROGRAMS_SORTED_FILE | cut -f 2 -d $'\t' | sort -u >$PROGRAMS_TITLE_FILE
grep '/us/' $EPISODES_SORTED_FILE | cut -f 5 -d $'\t' | sort -u >$EPISODES_TITLE_FILE

comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -e 's/^/    /' >>$ERROR_FILE
missingTitles=$(comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -n '$=')
echo "==> $missingTitles Program titles not found in $EPISODES_SORTED_FILE" >&2

# Print header for possible errors that occur during processing
printf "\n### Program URLs not found in $EPISODES_SORTED_FILE are listed below.\n\n" >>$ERROR_FILE

rm -f $TEMP_FILE
awk -v EPISODES_SORTED_FILE=$EPISODES_SORTED_FILE -v SEASONS_SORTED_FILE=$SEASONS_SORTED_FILE \
    -v TEMP_FILE=$TEMP_FILE -f verifyBBoxDownloadsFrom-webscraper.awk $PROGRAMS_SORTED_FILE \
    >>$EPISODE_INFO_FILE
sort -df $TEMP_FILE >>$ERROR_FILE
echo "" >>$ERROR_FILE

exit
