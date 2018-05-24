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

cp -p $VERBOSE $COLUMNS/Acorn-first$DATE.txt $BASELINE/Acorn-first.txt
cp -p $VERBOSE $COLUMNS/BBox-first$DATE.txt $BASELINE/BBox-first.txt
cp -p $VERBOSE $COLUMNS/MHz-first$DATE.txt $BASELINE/MHz-first.txt

cp -p $VERBOSE $COLUMNS/Acorn-search$DATE.txt $BASELINE/Acorn-search.txt
cp -p $VERBOSE $COLUMNS/BBox-search$DATE.txt $BASELINE/BBox-search.txt
cp -p $VERBOSE $COLUMNS/MHz-search$DATE.txt $BASELINE/MHz-search.txt

