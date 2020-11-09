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

COLS="IMDb-columns"
BASELINE="IMDb-baseline"
mkdir -p $COLS $BASELINE

# Copy standard files
cp -p $VERBOSE $COLS/tconst_all-$DATE.txt $BASELINE/tconst_all.txt
cp -p $VERBOSE $COLS/tconst-$DATE.txt $BASELINE/tconst.txt
cp -p $VERBOSE $COLS/nconst-$DATE.txt $BASELINE/nconst.txt
cp -p $VERBOSE $COLS/raw_shows-$DATE.csv $BASELINE/raw_shows.csv
cp -p $VERBOSE $COLS/raw_persons-$DATE.csv $BASELINE/raw_persons.csv
cp -p $VERBOSE $COLS/tconst_known-$DATE.txt $BASELINE/tconst_known.txt
cp -p $VERBOSE $COLS/tconst-episodes-$DATE.txt $BASELINE/tconst-episodes.csv

cp -p $VERBOSE IMDb_uniqTitles-$DATE.txt $BASELINE/uniqTitles.txt
cp -p $VERBOSE IMDb_uniqPersons-$DATE.txt $BASELINE/uniqPersons.txt

cp -p $VERBOSE IMDb_Shows-$DATE.csv $BASELINE/shows.csv
cp -p $VERBOSE IMDb_Credits-Show-$DATE.csv $BASELINE/credits-show.csv
cp -p $VERBOSE IMDb_Credits-Person-$DATE.csv $BASELINE/credits-person.csv
cp -p $VERBOSE IMDb_Persons-Titles-$DATE.csv $BASELINE/persons-titles.csv
cp -p $VERBOSE IMDb_associatedTitles-$DATE.csv $BASELINE/associatedTitles.csv
cp -p $VERBOSE IMDb_suggestedEpisodes-$DATE.csv $BASELINE/suggestedEpisodes.csv
