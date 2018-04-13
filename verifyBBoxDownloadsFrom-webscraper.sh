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

PROGRAMS_FILE="$SCRAPES/BBoxPrograms.csv"
EPISODES_FILE="$SCRAPES/BBoxEpisodes$NEWDATE.csv"
SEASONS_FILE="$SCRAPES/BBoxSeasons$NEWDATE.csv"
#
EPISODE_INFO_FILE="checkEpisodeInfo-$LONGDATE.txt"
ERROR_FILE="checkBBox_anomalies-$LONGDATE.txt"

if [ "$VERBOSE" != "" ]; then
    echo "PROGRAMS_FILE = $PROGRAMS_FILE"
    echo "EPISODES_FILE = $EPISODES_FILE"
    echo "SEASONS_FILE = $SEASONS_FILE"
    echo ""
    echo "EPISODE_INFO_FILE = $EPISODE_INFO_FILE"
    echo "ERROR_FILE = $ERROR_FILE"
    echo ""
fi

# Print header for verifying episodes across webscraper downloads
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE

# Print header for possible errors that occur during processing
printf "### Possible missing episodes are listed below.\n\n" >$ERROR_FILE

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | sort -df --field-separator=$',' --key=3 |
    awk -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE \
        -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
        -f verifyBBoxDownloadsFrom-webscraper.awk
