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

COLUMNS="BBox-columns"
BASELINE="BBox-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/BBoxPrograms-$DATE.csv $BASELINE/BBoxPrograms.txt
cp -p $VERBOSE $COLUMNS/BBoxSeasons-$DATE.csv $BASELINE/BBoxSeasons.txt
cp -p $VERBOSE $COLUMNS/BBoxEpisodes-$DATE.csv $BASELINE/BBoxEpisodes.txt
cp -p $VERBOSE $COLUMNS/duration-$DATE.csv $BASELINE/duration.txt

cp -p $VERBOSE BBox_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt 2>/dev/null
cp -p $VERBOSE BBox_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt 2>/dev/null
cp -p $VERBOSE BBoxSeasons-sorted-$DATE.csv $BASELINE/seasons-sorted.txt 2>/dev/null
