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

cp -p $VERBOSE $COLUMNS/BBoxCatalog-$DATE.csv $BASELINE/BBoxCatalog.txt
cp -p $VERBOSE $COLUMNS/total_duration-$DATE.txt $BASELINE/total_duration.txt
cp -p $VERBOSE $COLUMNS/uniqCharacters-$DATE.txt $BASELINE/uniqCharacters.txt
cp -p $VERBOSE $COLUMNS/uniqPersons-$DATE.txt $BASELINE/uniqPersons.txt
cp -p $VERBOSE $COLUMNS/uniqTitles-$DATE.txt $BASELINE/uniqTitles.txt

cp -p $VERBOSE BBox_TV_Credits-$DATE.csv $BASELINE/credits.txt
cp -p $VERBOSE BBox_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt
cp -p $VERBOSE BBox_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt
