#!/usr/bin/env bash
# Save the current days results as a baseline so we can check for changes in the future
# -d DATE picks a different date
# -v does verbose copying

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Create a timestamp
DATE="$(date +%y%m%d)"

# Allow user to override DATE
while getopts ":d:v" opt; do
    case $opt in
    d)
        DATE="$OPTARG"
        ;;
    v)
        VERBOSE="-v"
        ;;
    \?)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    :)
        printf "Option -$OPTARG requires a 'date' argument such as $DATE\n" >&2
        exit 1
        ;;
    esac
done

COLUMNS="IMDb-columns"
BASELINE="IMDb-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/tconst-$DATE.txt $BASELINE/tconst.txt
cp -p $VERBOSE $COLUMNS/titles-$DATE.txt $BASELINE/titles.txt
cp -p $VERBOSE $COLUMNS/nconst-$DATE.txt $BASELINE/nconst.txt
cp -p $VERBOSE $COLUMNS/raw_shows-$DATE.csv $BASELINE/raw_shows.csv
cp -p $VERBOSE $COLUMNS/raw_credits-$DATE.csv $BASELINE/raw_credits.csv

cp -p $VERBOSE IMDb_Credits-Show-$DATE.csv $BASELINE/credits-show.csv
cp -p $VERBOSE IMDb_Credits-Person-$DATE.csv $BASELINE/credits-person.csv
cp -p $VERBOSE IMDb_Shows-$DATE.csv $BASELINE/shows.csv
