#! /bin/bash
# Create a .csv spreadsheet of shows available on MHz Networks

DATE=`date "+%y%m%d"`
LONGDATE=`date "+%y%m%d.%H%M%S"`

COLUMNS="MHz-columns"
BASELINE="MHz-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveLatestMHzFiles.sh
# so if you change them here, change them there as well
# they are named with today's date so running them twice
# in one day will only generate one set of results
URL_FILE="$COLUMNS/urls-$DATE.csv"
PUBLISHED_URLS="$BASELINE/urls.txt"
NAME_FILE="$COLUMNS/names-$DATE.csv"
PUBLISHED_NAMES="$BASELINE/names.txt"
TITLE_FILE="$COLUMNS/titles-$DATE.csv"
PUBLISHED_TITLES="$BASELINE/titles.txt"
DESCRIPTION_FILE="$COLUMNS/descriptions-$DATE.csv"
PUBLISHED_DESCRIPTIONS="$BASELINE/descriptions.txt"
SEASONS_FILE="$COLUMNS/numberOfSeasons-$DATE.csv"
PUBLISHED_SEASONS="$BASELINE/numberOfSeasons.txt"
EPISODES_FILE="$COLUMNS/numberOfEpisodes-$DATE.csv"
PUBLISHED_EPISODES="$BASELINE/numberOfEpisodes.txt"
HEADER_FILE="$COLUMNS/headers-$DATE.csv"
PUBLISHED_HEADERS="$BASELINE/headers.txt"
#
SPREADSHEET_FILE="MHz_TV_Shows-$DATE.csv"
PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
#
# Name diffs with both date and time so every run produces a new result
POSSIBLE_DIFFS="MHz_diffs-$LONGDATE.txt"

rm -f $URL_FILE $NAME_FILE $TITLE_FILE $DESCRIPTION_FILE \
    $SEASONS_FILE $EPISODES_FILE $HEADER_FILE $SPREADSHEET_FILE

curl -s https://mhzchoice.vhx.tv/series https://mhzchoice.vhx.tv/series?page=2 \
    | awk -v TITLE_FILE=$TITLE_FILE -v URL_FILE=$URL_FILE  \
    -v SEASONS_FILE=$SEASONS_FILE -f fetchMHz-series.awk

# keep track of the number of series we find
lastRow=1
while read line
do
    ((lastRow++))
    curl -sS $line \
    | tee \
        >(awk -v NAME_FILE=$NAME_FILE -v HEADER_FILE=$HEADER_FILE \
            -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
            -f fetchMHz-episodeInfo.awk) \
    | sed -n -f fetchMHz-seasonURLs.sed \
        | while read episode
            do
                if [[ "${episode}" =~ season:1 ]] ; then
                    if [[ -e "$EPISODES_FILE" ]] ; then
                        echo >>$EPISODES_FILE
                    fi
                    echo -n "=" >>$EPISODES_FILE
                fi
                curl -sS $episode \
                | sed -n -f fetchMHz-numberOfEpisodes.sed \
                | echo -n "+`cat`" >>$EPISODES_FILE
            done
done < "$URL_FILE"
echo >>$EPISODES_FILE

echo -e \
    '#\tTitle\tURL\tSeasons\tEpisodes\tGenre\tCountry\tLanguage\tRating\tDescription' \
    >$SPREADSHEET_FILE
paste $TITLE_FILE $URL_FILE $SEASONS_FILE $EPISODES_FILE $HEADER_FILE \
    $DESCRIPTION_FILE \
    | nl >>$SPREADSHEET_FILE
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
    echo "==> $2 did not exist. Creating it, assuming no diffs."
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

`checkdiffs $NAME_FILE $TITLE_FILE`

`checkdiffs $TITLE_FILE $PUBLISHED_TITLES`
`checkdiffs $URL_FILE $PUBLISHED_URLS`
`checkdiffs $NAME_FILE $PUBLISHED_NAMES`
`checkdiffs $DESCRIPTION_FILE $PUBLISHED_DESCRIPTIONS`
`checkdiffs $SEASONS_FILE $PUBLISHED_SEASONS`
`checkdiffs $EPISODES_FILE $PUBLISHED_EPISODES`
`checkdiffs $HEADER_FILE $PUBLISHED_HEADERS`


### Any funny stuff with file lengths?
`wc $COLUMNS/*$DATE.csv`

EOF

echo
echo "==> ${0##*/} completed: `date`"

