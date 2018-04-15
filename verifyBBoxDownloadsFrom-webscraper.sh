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

SCRAPES="BritBox-scrapes"
COLUMNS="$SCRAPES/columns"

mkdir -p $SCRAPES $COLUMNS

PROGRAMS_FILE="$SCRAPES/BBoxPrograms.csv"
EPISODES_FILE="$SCRAPES/BBoxEpisodes$NEWDATE.csv"
SEASONS_FILE="$SCRAPES/BBoxSeasons$NEWDATE.csv"
#
PROGRAMS_TITLE_FILE="$COLUMNS/UniqTitle-BBoxPrograms.csv"
EPISODES_TITLE_FILE="$COLUMNS/UniqTitle-BBoxEpisodes$NEWDATE.csv"
#
EPISODE_INFO_FILE="checkEpisodeInfo-$LONGDATE.txt"
ERROR_FILE="checkBBox_anomalies-$LONGDATE.txt"
rm -f $ERROR_FILE

if [ "$VERBOSE" != "" ]; then
    echo "PROGRAMS_FILE = $PROGRAMS_FILE" >>$ERROR_FILE
    echo "EPISODES_FILE = $EPISODES_FILE" >>$ERROR_FILE
    echo "SEASONS_FILE = $SEASONS_FILE" >>$ERROR_FILE
    echo "" >>$ERROR_FILE
    echo "PROGRAMS_TITLE_FILE = " $PROGRAMS_TITLE_FILE >>$ERROR_FILE
    echo "EPISODES_TITLE_FILE = " $EPISODES_TITLE_FILE >>$ERROR_FILE
    echo "" >>$ERROR_FILE
fi

# Print header for verifying episodes across webscraper downloads
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE

# Print header for possible errors that occur during processing
printf "### Program Titles not found in $EPISODES_FILE are listed below.\n\n" >>$ERROR_FILE

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | grep 'www.britbox.com' |
    sort -df --field-separator=$',' --key=3 | cut -f 8 -d "\"" | sort -u >$PROGRAMS_TITLE_FILE 
awk -f fixExtraLinesFrom-webscraper.awk $EPISODES_FILE | grep 'www.britbox.com' |
    sort -df --field-separator=$',' --key=3 | cut -f 12 -d "\"" | sort -u >$EPISODES_TITLE_FILE
comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -e 's/^/    /' >>$ERROR_FILE
missingTitles=$(comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -n '$=')
echo "==> $missingTitles Program titles not found in $EPISODES_FILE" >&2

# Print header for possible errors that occur during processing
printf "\n### Program URLs not found in $EPISODES_FILE are listed below.\n\n" >>$ERROR_FILE

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | sort -df --field-separator=$',' --key=3 |
    awk -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE \
        -v ERROR_FILE=$ERROR_FILE -f verifyBBoxDownloadsFrom-webscraper.awk >>$EPISODE_INFO_FILE
