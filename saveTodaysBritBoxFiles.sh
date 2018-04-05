#! /bin/bash
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

COLUMNS="BritBox-columns"
BASELINE="BritBox-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/BritBoxPrograms-$DATE.csv $BASELINE/BritBoxPrograms.txt
cp -p $VERBOSE $COLUMNS/BritBoxSeasons-$DATE.csv $BASELINE/BritBoxSeasons.txt
cp -p $VERBOSE $COLUMNS/BritBoxEpisodes-$DATE.csv $BASELINE/BritBoxEpisodes.txt

cp -p $VERBOSE BritBox_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt 2>/dev/null
cp -p $VERBOSE BritBox_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt 2>/dev/null
cp -p $VERBOSE BritBoxSeasons-sorted-$DATE.csv $BASELINE/seasons-sorted.txt 2>/dev/null
