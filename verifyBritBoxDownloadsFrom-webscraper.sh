#! /bin/bash

# Check that the current downloads from WebScraper are in sync with each other

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

COLUMNS="BritBox-columns"

PROGRAMS_FILE="$COLUMNS/BritBoxPrograms.csv"
EPISODES_FILE="$COLUMNS/BritBoxEpisodes.csv"
SEASONS_FILE="$COLUMNS/BritBoxSeasons.csv"

awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | sort -df --field-separator=$',' --key=3 |
    awk -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE \
    -f verifyBritBoxDownloadsFrom-webscraper.awk
