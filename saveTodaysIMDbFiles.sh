#! /bin/bash
# Save the current days results as a baseline so we can check for changes in the future
# -d DATE picks a different date
# -v does verbose copying

DATE="-$(date +%y%m%d)"

# Allow user to override DATE
while getopts ":d:v" opt; do
    case $opt in
    d)
        DATE="-$OPTARG"
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

COLUMNS="IMDb-columns"
BASELINE="IMDb-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/Acorn-titles$DATE.txt $BASELINE/Acorn-titles.txt
cp -p $VERBOSE $COLUMNS/BBox-titles$DATE.txt $BASELINE/BBox-titles.txt
cp -p $VERBOSE $COLUMNS/MHz-titles$DATE.txt $BASELINE/MHz-titles.txt
cp -p $VERBOSE $COLUMNS/Watched-titles$DATE.txt $BASELINE/Watched-titles.txt

cp -p $VERBOSE $COLUMNS/Acorn-IMDb_Info$DATE.csv $BASELINE/Acorn-IMDb_Info.csv  2>/dev/null
cp -p $VERBOSE $COLUMNS/BBox-IMDb_Info$DATE.csv $BASELINE/BBox-IMDb_Info.csv  2>/dev/null
cp -p $VERBOSE $COLUMNS/MHz-IMDb_Info$DATE.csv $BASELINE/MHz-IMDb_Info.csv  2>/dev/null
cp -p $VERBOSE $COLUMNS/Watched-IMDb_Info$DATE.csv $BASELINE/Watched-IMDb_Info.csv  2>/dev/null

cp -p $VERBOSE $COLUMNS/Acorn-IMDb_IDs$DATE.txt $BASELINE/Acorn-IMDb_IDs.txt  2>/dev/null
cp -p $VERBOSE $COLUMNS/BBox-IMDb_IDs$DATE.txt $BASELINE/BBox-IMDb_IDs.txt  2>/dev/null
cp -p $VERBOSE $COLUMNS/MHz-IMDb_IDs$DATE.txt $BASELINE/MHz-IMDb_IDs.txt  2>/dev/null
cp -p $VERBOSE $COLUMNS/Watched-IMDb_IDs$DATE.txt $BASELINE/Watched-IMDb_IDs.txt  2>/dev/null
