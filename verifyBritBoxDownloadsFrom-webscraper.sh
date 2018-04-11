#! /bin/bash

# Check that the current downloads from WebScraper are in sync with each other

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

SCRAPES="BritBox-scrapes"

PROGRAMS_FILE="$SCRAPES/BritBoxPrograms.csv"
EPISODES_FILE="$SCRAPES/BritBoxEpisodes.csv"
SEASONS_FILE="$SCRAPES/BritBoxSeasons.csv"
#
EPISODE_INFO_FILE="checkEpisodeInfo-$LONGDATE.txt"
ERROR_FILE="checkBritBox_anomalies-$LONGDATE.txt"

# Print header for verifying episodes across webscraper downloads
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE

# Print header for possible errors that occur during processing
printf "### Possible missing episodes are listed below.\n\n" >$ERROR_FILE

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | sort -df --field-separator=$',' --key=3 |
    awk -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE \
    -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f verifyBritBoxDownloadsFrom-webscraper.awk
