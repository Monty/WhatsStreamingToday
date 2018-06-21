#!/usr/bin/env bash
# Use the URLs output by getBBoxProgramsFrom-webscraper.json to generate json scrapers
# with a per show startUrl instead of the top level "https://www.britbox.com/us/programmes"
#
# Then use the resulting json files to scrape current movies and episodes

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

SCRAPES="BBox-scrapes"

PROGRAMS_FILE="$SCRAPES/BBoxPrograms.csv"
#
PROGRAMS_ID="BBoxPrograms-$LONGDATE"
EPISODES_ID="BBoxEpisodes-$LONGDATE"
SEASONS_ID="BBoxSeasons-$LONGDATE"
#
PROGRAMS_JSON_FILE="$PROGRAMS_ID.json"
EPISODES_JSON_FILE="$EPISODES_ID.json"
SEASONS_JSON_FILE="$SEASONS_ID.json"

sed -e "s/BBoxPrograms/$PROGRAMS_ID/" programTemplate.json >$PROGRAMS_JSON_FILE

grep -B4 startUrl episodeTemplate.json | sed -e "s/BBoxEpisodes/$EPISODES_ID/" >$EPISODES_JSON_FILE
grep -B4 startUrl seasonTemplate.json | sed -e "s/BBoxSeasons/$SEASONS_ID/" >$SEASONS_JSON_FILE

grep 'www.britbox.com' $PROGRAMS_FILE | sort -df --field-separator=$',' --key=3 |
    awk -v EPISODES_JSON_FILE=$EPISODES_JSON_FILE -v SEASONS_JSON_FILE=$SEASONS_JSON_FILE \
        -f buildBBoxScrapersFrom-webscraper.awk

grep -B1 -A99 selectors episodeTemplate.json >>$EPISODES_JSON_FILE
grep -B1 -A99 selectors seasonTemplate.json >>$SEASONS_JSON_FILE
