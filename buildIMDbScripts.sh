#! /bin/bash
# Use the titles from various scrapers to compile a list of shows we might want info about.
# Create a dated shell script to obtain that info

while getopts ":ls" opt; do
    case $opt in
    l)
        LONG="yes"
        ;;
   s)
        SUMMARY="yes"
        ;;
    \?)
        echo "Ignoring invalid option: -$OPTARG" >&2
        ;;
    esac
done
shift $((OPTIND - 1))

DATE_ID="-$(date +%y%m%d)"
#
SCRIPT="getInfoFrom-IMDb$DATE_ID.sh"
#
COLUMNS="IMDb-columns"
mkdir -p $COLUMNS
#
ACORN_CSV=$(ls -1t Acorn_TV_Shows-*csv | head -1)
BBOX_CSV=$(ls -1t BBox_TV_Shows-*csv | head -1)
MHZ_CSV=$(ls -1t MHz_TV_Shows-*csv | head -1)
# echo ACORN=$ACORN
# echo BBOX=$BBOX
# echo MHZ=$MHZ
#
ACORN_TITLES="$COLUMNS/Acorn-titles$DATE_ID.txt"
BBOX_TITLES="$COLUMNS/BBox-titles$DATE_ID.txt"
MHZ_TITLES="$COLUMNS/MHz-titles$DATE_ID.txt"
#
ACORN_FIRST_SCRIPT="getIMDbFrom-Acorn_first$DATE_ID.sh"
BBOX_FIRST_SCRIPT="getIMDbFrom-BBox_first$DATE_ID.sh"
MHZ_FIRST_SCRIPT="getIMDbFrom-MHz_first$DATE_ID.sh"
#
ACORN_SEARCH_SCRIPT="getIMDbFrom-Acorn_search$DATE_ID.sh"
BBOX_SEARCH_SCRIPT="getIMDbFrom-BBox_search$DATE_ID.sh"
MHZ_SEARCH_SCRIPT="getIMDbFrom-MHz_search$DATE_ID.sh"
#
ACORN_FIRST_FILE="$COLUMNS/Acorn-first$DATE_ID.txt"
BBOX_FIRST_FILE="$COLUMNS/BBox-first$DATE_ID.txt"
MHZ_FIRST_FILE="$COLUMNS/MHz-first$DATE_ID.txt"
#
ACORN_SEARCH_FILE="$COLUMNS/Acorn-search$DATE_ID.txt"
BBOX_SEARCH_FILE="$COLUMNS/BBox-search$DATE_ID.txt"
MHZ_SEARCH_FILE="$COLUMNS/MHz-search$DATE_ID.txt"

rm -f $ACORN_FIRST_SCRIPT $BBOX_FIRST_SCRIPT $MHZ_FIRST_SCRIPT
rm -f $ACORN_SEARCH_SCRIPT $BBOX_SEARCH_SCRIPT $MHZ_SEARCH_SCRIPT

grep HYPERLINK $ACORN_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$ACORN_TITLES
grep HYPERLINK $BBOX_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$BBOX_TITLES
grep HYPERLINK $MHZ_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$MHZ_TITLES

awk -v FIRST_SCRIPT=$ACORN_FIRST_SCRIPT -v SEARCH_SCRIPT=$ACORN_SEARCH_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $ACORN_TITLES 
awk -v FIRST_SCRIPT=$BBOX_FIRST_SCRIPT -v SEARCH_SCRIPT=$BBOX_SEARCH_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $BBOX_TITLES
awk -v FIRST_SCRIPT=$MHZ_FIRST_SCRIPT -v SEARCH_SCRIPT=$MHZ_SEARCH_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $MHZ_TITLES

if [ "$LONG" != "yes" ]; then
    exit
fi

bash $ACORN_FIRST_SCRIPT > $ACORN_FIRST_FILE
bash $BBOX_FIRST_SCRIPT > $BBOX_FIRST_FILE
bash $MHZ_FIRST_SCRIPT > $MHZ_FIRST_FILE

bash $ACORN_SEARCH_SCRIPT > $ACORN_SEARCH_FILE
bash $BBOX_SEARCH_SCRIPT > $BBOX_SEARCH_FILE
bash $MHZ_SEARCH_SCRIPT > $MHZ_SEARCH_FILE
