#! /bin/bash
# Use the URLs output by getBritBoxProgramsFrom-webscraper.json to generate json scrapers
# with a per show startUrl instead of the top level "https://www.britbox.com/us/programmes"
#
# Then use the resulting json files to scrape current movies and shows 

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

SCRAPES="BritBox-scrapes"

PROGRAMS_FILE="$SCRAPES/BritBoxPrograms.csv"
MOVIES_JSON_FILE="BritBoxMovies-$LONGDATE.json"
SHOWS_JSON_FILE="BritBoxShows-$LONGDATE.json"

grep -B4 startUrl movieTemplate.json > $MOVIES_JSON_FILE
grep -B4 startUrl showTemplate.json > $SHOWS_JSON_FILE

awk -v MOVIES_JSON_FILE=$MOVIES_JSON_FILE -v SHOWS_JSON_FILE=$SHOWS_JSON_FILE \
    -f buildBritBoxScrapersFrom-webscraper.awk $PROGRAMS_FILE

grep -B1 -A99 selectors movieTemplate.json >> $MOVIES_JSON_FILE
grep -B1 -A99 selectors showTemplate.json >> $SHOWS_JSON_FILE
