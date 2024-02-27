#!/usr/bin/env bash
# Save the current days results as a baseline so we can check for changes in the future
# -d DATE picks a different date
# -v does verbose copying

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME/Walter-Presents

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

COLS="OPB-columns"
BASELINE="OPB-baseline"
mkdir -p $COLS $BASELINE

cp -p $VERBOSE $COLS/episode_ids-$DATE.csv $BASELINE/episode_ids.txt
cp -p $VERBOSE $COLS/show_urls-$DATE.txt $BASELINE/show_urls.txt
cp -p $VERBOSE $COLS/logfile-$DATE.txt $BASELINE/logfile.txt
cp -p $VERBOSE $COLS/total_duration-$DATE.txt $BASELINE/total_duration.txt

cp -p $VERBOSE OPB_uniqTitles-$DATE.txt $BASELINE/uniqTitles.txt
cp -p $VERBOSE OPB_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt
cp -p $VERBOSE OPB_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt
