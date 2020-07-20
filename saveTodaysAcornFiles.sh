#!/usr/bin/env bash
# Save the current days results as a baseline so we can check for changes in the future
# -d DATE picks a different date
# -v does verbose copying

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

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/show_urls-$DATE.txt $BASELINE/show_urls.txt
cp -p $VERBOSE $COLUMNS/uniqTitles-$DATE.txt $BASELINE/uniqTitles.txt

cp -p $VERBOSE Acorn_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt 2>/dev/null
# cp -p $VERBOSE Acorn_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt 2>/dev/null
