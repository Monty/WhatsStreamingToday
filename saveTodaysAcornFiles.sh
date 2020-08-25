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

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/episode_urls-$DATE.txt $BASELINE/episode_urls.txt
cp -p $VERBOSE $COLUMNS/show_urls-$DATE.txt $BASELINE/show_urls.txt
cp -p $VERBOSE $COLUMNS/uniqTitles-$DATE.txt $BASELINE/uniqTitles.txt

cp -p $VERBOSE Acorn_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt
cp -p $VERBOSE Acorn_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt
