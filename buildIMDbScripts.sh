#! /bin/bash
# Use the titles from various scrapers to compile a list of shows we might want info about.
# Create a dated shell script to obtain that info

while getopts ":dls" opt; do
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
ACORN_TITLES_FILE="$COLUMNS/Acorn-titles$DATE_ID.txt"
BBOX_TITLES_FILE="$COLUMNS/BBox-titles$DATE_ID.txt"
MHZ_TITLES_FILE="$COLUMNS/MHz-titles$DATE_ID.txt"
WATCHED_TITLES_FILE="$COLUMNS/Watched-titles$DATE_ID.txt"
#
ACORN_ID_FILE="$COLUMNS/Acorn-IDs$DATE_ID.txt"
BBOX_ID_FILE="$COLUMNS/BBox-IDs$DATE_ID.txt"
MHZ_ID_FILE="$COLUMNS/MHz-IDs$DATE_ID.txt"
WATCHED_ID_FILE="$COLUMNS/Watched-IDs$DATE_ID.txt"

rm -f $ACORN_TITLES_SCRIPT $BBOX_TITLES_SCRIPT $MHZ_TITLES_SCRIPT $WATCHED_TITLES_SCRIPT
rm -f $ACORN_ID_SCRIPT $BBOX_ID_SCRIPT $MHZ_ID_SCRIPT $WATCHED_ID_SCRIPT

grep HYPERLINK $ACORN_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$ACORN_TITLES
grep HYPERLINK $BBOX_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$BBOX_TITLES
grep HYPERLINK $MHZ_CSV | cut -f 2 | sed -e 's/=HYPER.*;//' | sed -e 's/)$//' >$MHZ_TITLES
sed -E -f fixWatched_titles.sed $WATCHED_TXT | sort -u >$WATCHED_TITLES

awk -v TITLES_SCRIPT=$ACORN_TITLES_SCRIPT -v ID_SCRIPT=$ACORN_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $ACORN_TITLES
awk -v TITLES_SCRIPT=$BBOX_TITLES_SCRIPT -v ID_SCRIPT=$BBOX_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $BBOX_TITLES
awk -v TITLES_SCRIPT=$MHZ_TITLES_SCRIPT -v ID_SCRIPT=$MHZ_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $MHZ_TITLES
awk -v TITLES_SCRIPT=$WATCHED_TITLES_SCRIPT -v ID_SCRIPT=$WATCHED_ID_SCRIPT \
    -f generateIMDbScriptsFrom-titles.awk $WATCHED_TITLES

if [ "$LONG" != "yes" ]; then
    exit
fi

bash $ACORN_TITLES_SCRIPT >$ACORN_TITLES_FILE
bash $BBOX_TITLES_SCRIPT >$BBOX_TITLES_FILE
bash $MHZ_TITLES_SCRIPT >$MHZ_TITLES_FILE
bash $WATCHED_TITLES_SCRIPT >$WATCHED_TITLES_FILE

bash $ACORN_ID_SCRIPT >$ACORN_ID_FILE
bash $BBOX_ID_SCRIPT >$BBOX_ID_FILE
bash $MHZ_ID_SCRIPT >$MHZ_ID_FILE
bash $WATCHED_ID_SCRIPT >$WATCHED_ID_FILE
