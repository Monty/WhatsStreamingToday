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
        echo "Ignoring invalid option: -$OPTARG" >&2
        ;;
    :)
        echo "Option -$OPTARG requires a 'date' argument such as $DATE" >&2
        exit 1
        ;;
    esac
done

COLUMNS="BBox-columns"
BASELINE="BBox-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/BBoxCatalog-$DATE.csv $BASELINE/BBoxCatalog.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/BBoxPrograms-$DATE.csv $BASELINE/BBoxPrograms.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/BBoxEpisodes-$DATE.csv $BASELINE/BBoxEpisodes.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/BBoxSeasons-$DATE.csv $BASELINE/BBoxSeasons.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/BBoxMovies-$DATE.csv $BASELINE/BBoxMovies.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/uniqTitles-$DATE.csv $BASELINE/uniqTitles.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/durations-$DATE.csv $BASELINE/durations.txt 2>/dev/null

cp -p $VERBOSE BBox_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt 2>/dev/null
cp -p $VERBOSE BBox_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt 2>/dev/null
