#!/usr/bin/env bash
# Save the current days noHype results as a baseline so we can check for changes in the future
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

# Copy -noHype files
cp -p $VERBOSE $COLS/tconst_all-noHype-$DATE.txt $BASELINE/tconst_all-noHype.txt
cp -p $VERBOSE $COLS/tconst-noHype-$DATE.txt $BASELINE/tconst-noHype.txt
cp -p $VERBOSE $COLS/nconst-noHype-$DATE.txt $BASELINE/nconst-noHype.txt
cp -p $VERBOSE $COLS/raw_shows-noHype-$DATE.csv $BASELINE/raw_shows-noHype.csv
cp -p $VERBOSE $COLS/raw_persons-noHype-$DATE.csv $BASELINE/raw_persons-noHype.csv
cp -p $VERBOSE $COLS/tconst_known-noHype-$DATE.txt $BASELINE/tconst_known-noHype.txt
cp -p $VERBOSE $COLS/tconst-episodes-noHype-$DATE.txt $BASELINE/tconst-episodes-noHype.csv

cp -p $VERBOSE IMDb_uniqTitles-noHype-$DATE.txt $BASELINE/uniqTitles-noHype.txt
cp -p $VERBOSE IMDb_uniqPersons-noHype-$DATE.txt $BASELINE/uniqPersons-noHype.txt

cp -p $VERBOSE IMDb_Shows-noHype-$DATE.csv $BASELINE/shows-noHype.csv
cp -p $VERBOSE IMDb_Credits-Show-noHype-$DATE.csv $BASELINE/credits-show-noHype.csv
cp -p $VERBOSE IMDb_Credits-Person-noHype-$DATE.csv $BASELINE/credits-person-noHype.csv
cp -p $VERBOSE IMDb_Persons-Titles-noHype-$DATE.csv $BASELINE/persons-titles-noHype.csv
cp -p $VERBOSE IMDb_associatedTitles-noHype-$DATE.csv $BASELINE/associatedTitles-noHype.csv
cp -p $VERBOSE IMDb_suggestedEpisodes-noHype-$DATE.csv $BASELINE/suggestedEpisodes-noHype.csv
