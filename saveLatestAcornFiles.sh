#! /bin/bash
# Save the current results as a baseline so we can check for changes in the future

DATE=`date "+%y%m%d"`

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $COLUMNS/urls-$DATE.csv $BASELINE/urls.txt
cp -p $COLUMNS/marquees-$DATE.csv $BASELINE/marquees.txt
cp -p $COLUMNS/titles-$DATE.csv $BASELINE/titles.txt
cp -p $COLUMNS/links-$DATE.csv $BASELINE/links.txt
cp -p $COLUMNS/descriptions-$DATE.csv $BASELINE/descriptions.txt
cp -p $COLUMNS/numberOfSeasons-$DATE.csv $BASELINE/numberOfSeasons.txt
cp -p $COLUMNS/numberOfEpisodes-$DATE.csv $BASELINE/numberOfEpisodes.txt

cp -p Acorn_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt
