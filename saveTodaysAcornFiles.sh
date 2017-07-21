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

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

cp -p $VERBOSE $COLUMNS/urls-$DATE.csv $BASELINE/urls.txt
cp -p $VERBOSE $COLUMNS/marquees-$DATE.csv $BASELINE/marquees.txt
cp -p $VERBOSE $COLUMNS/titles-$DATE.csv $BASELINE/titles.txt
cp -p $VERBOSE $COLUMNS/links-$DATE.csv $BASELINE/links.txt
cp -p $VERBOSE $COLUMNS/descriptions-$DATE.csv $BASELINE/descriptions.txt
cp -p $VERBOSE $COLUMNS/numberOfSeasons-$DATE.csv $BASELINE/numberOfSeasons.txt
cp -p $VERBOSE $COLUMNS/numberOfEpisodes-$DATE.csv $BASELINE/numberOfEpisodes.txt
cp -p $VERBOSE $COLUMNS/durations-$DATE.csv $BASELINE/durations.txt
cp -p $VERBOSE $COLUMNS/episodeUrls-$DATE.csv $BASELINE/episodeUrls.txt
cp -p $VERBOSE $COLUMNS/episodeInfo-$DATE.csv $BASELINE/episodeInfo.txt
cp -p $VERBOSE $COLUMNS/episodeDescription-$DATE.csv $BASELINE/episodeDescription.txt 2>/dev/null
cp -p $VERBOSE $COLUMNS/episodePasted-$DATE.csv $BASELINE/episodePasted.txt 2>/dev/null

cp -p $VERBOSE Acorn_TV_Shows-$DATE.csv $BASELINE/spreadsheet.txt 2>/dev/null
cp -p $VERBOSE Acorn_TV_ShowsEpisodes-$DATE.csv $BASELINE/spreadsheetEpisodes.txt 2>/dev/null
