#! /bin/bash
# Create a .csv spreadsheet of shows available on Acorn TV

DATE=`date "+%y%m%d"`
LONGDATE=`date "+%y%m%d.%H%M%S"`

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveLatestAcornFiles.sh
# so if you change them here, change them there as well
# they are named with today's date so running them twice
# in one day will only generate one set of results
URL_FILE="$COLUMNS/urls-$DATE.csv"
PUBLISHED_URLS="$BASELINE/urls.txt"
CAPTION_FILE="$COLUMNS/captions-$DATE.csv"
PUBLISHED_CAPTIONS="$BASELINE/captions.txt"
TITLE_FILE="$COLUMNS/titles-$DATE.csv"
PUBLISHED_TITLES="$BASELINE/titles.txt"
DESCRIPTION_FILE="$COLUMNS/descriptions-$DATE.csv"
PUBLISHED_DESCRIPTIONS="$BASELINE/descriptions.txt"
SEASONS_FILE="$COLUMNS/numberOfSeasons-$DATE.csv"
PUBLISHED_SEASONS="$BASELINE/numberOfSeasons.txt"
EPISODES_FILE="$COLUMNS/numberOfEpisodes-$DATE.csv"
PUBLISHED_EPISODES="$BASELINE/numberOfEpisodes.txt"
#
SPREADSHEET_FILE="Acorn_TV_Shows-$DATE.csv"
PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
#
# Name diffs with both date and time so every run produces a new result
POSSIBLE_DIFFS="Acorn_diffs-$LONGDATE.txt"

rm -f $URL_FILE $CAPTION_FILE $TITLE_FILE $DESCRIPTION_FILE \
    $SEASONS_FILE $EPISODES_FILE $SPREADSHEET_FILE

curl -s https://acorn.tv/browse \
    | awk -v CAPTION_FILE=$CAPTION_FILE -v URL_FILE=$URL_FILE -f fetchAcorn-series.awk

# keep track of the last spreadsheet row containing data
lastRow=1
while read line
do
    ((lastRow++))
    curl -s $line \
        | awk -v TITLE_FILE=$TITLE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
            -v SEASONS_FILE=$SEASONS_FILE -v EPISODES_FILE=$EPISODES_FILE \
            -f fetchAcorn-episodes.awk
done < "$URL_FILE"

echo -e "#\tTitle\tURL\tSeasons\tEpisodes\tDescription" >$SPREADSHEET_FILE
paste $TITLE_FILE $URL_FILE $SEASONS_FILE $EPISODES_FILE \
      $DESCRIPTION_FILE | nl >>$SPREADSHEET_FILE
echo -e \
    "\tTotal\t=COUNTA(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t=SUM(E2:E$lastRow)" \
    >>$SPREADSHEET_FILE

# Shortcut for checking differences between two files.
function checkdiffs () {
echo
if [ ! -e "$2" ] ; then
	# If the second file doesn't exist, assume no differences
	# and copy the first file to the second so it can serve
	# as a base for diffs in the future.
    echo "==> $2 does not exist. Creating it, assuming no diffs."
    cp -p $1 $2
else
    echo "### diff $1 $2"
    diff $1 $2
    if [ $? == 0 ]; then
        echo "### -- no diffs found --"
    fi
fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS << EOF
==> ${0##*/} completed: `date`

`checkdiffs $TITLE_FILE $CAPTION_FILE`

`checkdiffs $URL_FILE $PUBLISHED_URLS`
`checkdiffs $CAPTION_FILE $PUBLISHED_CAPTIONS`
`checkdiffs $TITLE_FILE $PUBLISHED_TITLES`
`checkdiffs $DESCRIPTION_FILE $PUBLISHED_DESCRIPTIONS`
`checkdiffs $SEASONS_FILE $PUBLISHED_SEASONS`
`checkdiffs $EPISODES_FILE $PUBLISHED_EPISODES`


### Any funny stuff with file lengths?
`wc $COLUMNS/*$DATE.csv`

EOF

echo
echo "==> ${0##*/} completed: `date`"

