#! /bin/bash
# Use the URLs output by getBritBoxProgramsFrom-webscraper.json to generate json scrapers
# with a per show startUrl instead of the top level "https://www.britbox.com/us/programmes"
#
# Then use the resulting json files to scrape current movies and episodes

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

SCRAPES="BritBox-scrapes"

PROGRAMS_FILE="$SCRAPES/BritBoxPrograms.csv"
#
MOVIES_ID="BBoxMovies-$LONGDATE"
EPISODES_ID="BBoxEpisodes-$LONGDATE"
SEASONS_ID="BBoxSeasons-$LONGDATE"
#
MOVIES_JSON_FILE="$MOVIES_ID.json"
EPISODES_JSON_FILE="$EPISODES_ID.json"
SEASONS_JSON_FILE="$SEASONS_ID.json"

grep -B4 startUrl movieTemplate.json | sed -e "s/BBoxMovies/$MOVIES_ID/" >$MOVIES_JSON_FILE
grep -B4 startUrl episodeTemplate.json | sed -e "s/BBoxEpisodes/$EPISODES_ID/" >$EPISODES_JSON_FILE
grep -B4 startUrl episodeTemplate.json | sed -e "s/BBoxSeasons/$SEASONS_ID/" >$SEASONS_JSON_FILE

awk -v MOVIES_JSON_FILE=$MOVIES_JSON_FILE -v EPISODES_JSON_FILE=$EPISODES_JSON_FILE \
    -v SEASONS_JSON_FILE=$SEASONS_JSON_FILE -f buildBBoxScrapersFrom-webscraper.awk $PROGRAMS_FILE

grep -B1 -A99 selectors movieTemplate.json >>$MOVIES_JSON_FILE
grep -B1 -A99 selectors episodeTemplate.json >>$EPISODES_JSON_FILE
grep -B1 -A99 selectors episodeTemplate.json >>$SEASONS_JSON_FILE
