#!/usr/bin/env bash
# Use the titles from various scrapers to compile a list of shows we might want info about.
# Create a dated shell script to obtain that info

while getopts ":dlsv" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    l)
        LONG="yes"
        ;;
    s)
        SUMMARY="yes"
        ;;
    v)
        VERBOSE="-v"
        ;;
    \?)
        echo "Ignoring invalid option: -$OPTARG" >&2
        ;;
    esac
done
shift $((OPTIND - 1))

DATE_ID="-$(date +%y%m%d)"
#
COLUMNS="IMDb-columns"
SCRAPES="IMDb-scrapes"
mkdir -p $COLUMNS
#
ACORN_CSV=$(ls -1t Acorn_TV_Shows-*csv | head -1)
BBOX_CSV=$(ls -1t BBox_TV_Shows-*csv | head -1)
MHZ_CSV=$(ls -1t MHz_TV_Shows-*csv | head -1)
WATCHED_TXT="$SCRAPES/watched_titles.txt"
# echo ACORN=$ACORN_CSV
# echo BBOX=$BBOX_CSV
# echo MHZ=$MHZ_CSV
# echo WATCHED=$WATCHED_TXT
#
ACORN_TITLES="$COLUMNS/Acorn-titles$DATE_ID.txt"
BBOX_TITLES="$COLUMNS/BBox-titles$DATE_ID.txt"
MHZ_TITLES="$COLUMNS/MHz-titles$DATE_ID.txt"
WATCHED_TITLES="$COLUMNS/Watched-titles$DATE_ID.txt"
#
ACORN_TITLES_SCRIPT="$COLUMNS/getIMDb_InfoFromAcorn-titles$DATE_ID.sh"
BBOX_TITLES_SCRIPT="$COLUMNS/getIMDb_InfoFromBBox-titles$DATE_ID.sh"
MHZ_TITLES_SCRIPT="$COLUMNS/getIMDb_InfoFromMHz-titles$DATE_ID.sh"
WATCHED_TITLES_SCRIPT="$COLUMNS/getIMDb_InfoFromWatched-titles$DATE_ID.sh"
#
ACORN_ID_SCRIPT="$COLUMNS/getIMDb_IDsFromAcorn-titles$DATE_ID.sh"
BBOX_ID_SCRIPT="$COLUMNS/getIMDb_IDsFromBBox-titles$DATE_ID.sh"
MHZ_ID_SCRIPT="$COLUMNS/getIMDb_IDsFromMHz-titles$DATE_ID.sh"
WATCHED_ID_SCRIPT="$COLUMNS/getIMDb_IDsFromWatched-titles$DATE_ID.sh"
#
ACORN_INFO_FILE="$COLUMNS/Acorn-IMDb_Info$DATE_ID.csv"
BBOX_INFO_FILE="$COLUMNS/BBox-IMDb_Info$DATE_ID.csv"
MHZ_INFO_FILE="$COLUMNS/MHz-IMDb_Info$DATE_ID.csv"
WATCHED_INFO_FILE="$COLUMNS/Watched-IMDb_Info$DATE_ID.csv"
#
ACORN_ID_FILE="$COLUMNS/Acorn-IMDb_IDs$DATE_ID.txt"
BBOX_ID_FILE="$COLUMNS/BBox-IMDb_IDs$DATE_ID.txt"
MHZ_ID_FILE="$COLUMNS/MHz-IMDb_IDs$DATE_ID.txt"
WATCHED_ID_FILE="$COLUMNS/Watched-IMDb_IDs$DATE_ID.txt"

rm -f $ACORN_TITLES_SCRIPT $BBOX_TITLES_SCRIPT $MHZ_TITLES_SCRIPT $WATCHED_TITLES_SCRIPT
rm -f $ACORN_ID_SCRIPT $BBOX_ID_SCRIPT $MHZ_ID_SCRIPT $WATCHED_ID_SCRIPT

grep HYPERLINK $ACORN_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$ACORN_TITLES
grep HYPERLINK $BBOX_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$BBOX_TITLES
grep HYPERLINK $MHZ_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$MHZ_TITLES
sed -E -f fixWatched_titles.sed $WATCHED_TXT | sort -u >$WATCHED_TITLES

awk -v TITLES_SCRIPT=$ACORN_TITLES_SCRIPT -v ID_SCRIPT=$ACORN_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles_or_IDs.awk $ACORN_TITLES
awk -v TITLES_SCRIPT=$BBOX_TITLES_SCRIPT -v ID_SCRIPT=$BBOX_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles_or_IDs.awk $BBOX_TITLES
awk -v TITLES_SCRIPT=$MHZ_TITLES_SCRIPT -v ID_SCRIPT=$MHZ_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles_or_IDs.awk $MHZ_TITLES
awk -v TITLES_SCRIPT=$WATCHED_TITLES_SCRIPT -v ID_SCRIPT=$WATCHED_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles_or_IDs.awk $WATCHED_TITLES

if [ "$LONG" != "yes" ]; then
    exit
fi

bash $VERBOSE $ACORN_TITLES_SCRIPT >$ACORN_INFO_FILE
bash $VERBOSE $BBOX_TITLES_SCRIPT >$BBOX_INFO_FILE
bash $VERBOSE $MHZ_TITLES_SCRIPT >$MHZ_INFO_FILE
bash $VERBOSE $WATCHED_TITLES_SCRIPT >$WATCHED_INFO_FILE

bash $VERBOSE $ACORN_ID_SCRIPT >$ACORN_ID_FILE
bash $VERBOSE $BBOX_ID_SCRIPT >$BBOX_ID_FILE
bash $VERBOSE $MHZ_ID_SCRIPT >$MHZ_ID_FILE
bash $VERBOSE $WATCHED_ID_SCRIPT >$WATCHED_ID_FILE
