#!/usr/bin/env bash
# Rebuild Acorn-baseline from an Acorn_TV_ShowsEpisodes spreadsheet
# -d DATE picks a different date

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
shift $((OPTIND - 1))

BASELINE="Acorn-baseline-$DATE"
mkdir -p $VERBOSE $BASELINE

rm -f $VERBOSE $BASELINE/*

awk -v VERBOSE=$VERBOSE \
    -v DESCRIPTIONS=$BASELINE/descriptions.txt \
    -v DURATIONS=$BASELINE/durations.txt \
    -v EPISODE_CURLS=$BASELINE/episodeCurls.txt \
    -v EPISODE_DESCRIPTION=$BASELINE/episodeDescription.txt \
    -v EPISODE_INFO=$BASELINE/episodeInfo.txt \
    -v LINKS=$BASELINE/links.txt \
    -v MARQUEES=$BASELINE/marquees.txt \
    -v NUMBER_OF_EPISODES=$BASELINE/numberOfEpisodes.txt \
    -v NUMBER_OF_SEASONS=$BASELINE/numberOfSeasons.txt \
    -v TITLES=$BASELINE/titles.txt \
    -v URLS=$BASELINE/urls.txt \
    -f rebuildAcornBaseline.awk \
    Acorn_TV_ShowsEpisodes-$DATE.csv

for file in $(ls $BASELINE/*.txt); do
    sort $file | cut -f 2- >$file.tmp
    mv $VERBOSE $file.tmp $file
done

paste $BASELINE/episodeInfo.txt $BASELINE/episodeDescription.txt >$BASELINE/episodePasted.txt

cp -p $VERBOSE Acorn_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt 2>/dev/null
cp -p $VERBOSE Acorn_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt 2>/dev/null
