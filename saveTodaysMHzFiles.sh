#!/usr/bin/env bash
# Save the current days results as a baseline so we can check for changes in the future
# -d DATE picks a different date
# -v does verbose copying
#
# shellcheck disable=SC2086

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

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

COLS="MHz-columns"
BASELINE="MHz-baseline"
mkdir -p $COLS $BASELINE

cp -p $VERBOSE $COLS/MHz_urls-"$DATE".txt $BASELINE/MHz_urls.txt
cp -p $VERBOSE $COLS/episode_urls-"$DATE".txt $BASELINE/episode_urls.txt
cp -p $VERBOSE $COLS/movie_urls-"$DATE".txt $BASELINE/movie_urls.txt
cp -p $VERBOSE $COLS/season_urls-"$DATE".txt $BASELINE/season_urls.txt
cp -p $VERBOSE $COLS/total_duration-"$DATE".txt $BASELINE/total_duration.txt

cp -p $VERBOSE MHz_uniqCharacters-"$DATE".txt $BASELINE/uniqCharacters.txt
cp -p $VERBOSE MHz_uniqPersons-"$DATE".txt $BASELINE/uniqPersons.txt
cp -p $VERBOSE MHz_uniqTitles-"$DATE".txt $BASELINE/uniqTitles.txt
cp -p $VERBOSE MHz_TV_Credits-"$DATE".csv $BASELINE/credits.txt
cp -p $VERBOSE MHz_TV_Shows-"$DATE".csv $BASELINE/spreadsheet.txt
cp -p $VERBOSE MHz_TV_ShowsEpisodes-"$DATE".csv $BASELINE/spreadsheetEpisodes.txt
