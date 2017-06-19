#! /bin/bash
# Create a .csv spreadsheet of shows available on MHz Networks

# Use "-t" switch to print a "Totals" line at the end of the spreadsheet
while getopts ":t" opt; do
    case $opt in
        t)
            PRINT_TOTALS="yes"
            ;;
        \?)
            echo "Ignoring invalid option: -$OPTARG" >&2
            ;;
    esac
done

# Make sure we can execute curl.
if [ ! -x "`which curl 2>/dev/null`" ] ; then
    echo "[Error] Can't run curl. Install curl and rerun this script."
    echo "        To test, type:  curl -Is https://github.com/ | head -5"
    exit 1
fi

# Make sure network is up and MHz Choice site is reachable
# While there are two URLs required at MHz, we only need to check one
BASE_URL="https://mhzchoice.vhx.tv/series"
BASE_URL2="https://mhzchoice.vhx.tv/series?page=2"
if ! curl -o /dev/null -Isf $BASE_URL ; then
    echo "[Error] $BASE_URL isn't available, or your network is down."
    echo "        Try accessing $BASE_URL in your browser"
    exit 1
fi

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
MARQUEE_FILE="$COLUMNS/marquees-$DATE.csv"
PUBLISHED_MARQUEES="$BASELINE/marquees.txt"
TITLE_FILE="$COLUMNS/titles-$DATE.csv"
PUBLISHED_TITLES="$BASELINE/titles.txt"
LINK_FILE="$COLUMNS/links-$DATE.csv"
PUBLISHED_LINKS="$BASELINE/links.txt"
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

rm -f $URL_FILE $MARQUEE_FILE $TITLE_FILE $LINK_FILE $DESCRIPTION_FILE \
    $SEASONS_FILE $EPISODES_FILE $HEADER_FILE $SPREADSHEET_FILE

curl -s $BASE_URL $BASE_URL2 \
    | awk -v URL_FILE=$URL_FILE -v TITLE_FILE=$TITLE_FILE \
    -v SEASONS_FILE=$SEASONS_FILE -f fetchMHz-series.awk

# keep track of the number of series we find
lastRow=1
while read line
do
    ((lastRow++))
    curl -sS $line \
    | tee \
        >(awk -v MARQUEE_FILE=$MARQUEE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
            -v HEADER_FILE=$HEADER_FILE -f fetchMHz-episodeInfo.awk) \
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
# Add newline
echo >>$EPISODES_FILE

# WARNING there is an actual tab character in the following command
# because sed in macOS doesn't regognize \t
paste $URL_FILE $TITLE_FILE \
    | sed -e 's/^/=HYPERLINK("/; s/	/"\;"/; s/$/")/' >>$LINK_FILE

echo -e \
    '#\tTitle\tSeasons\tEpisodes\tGenre\tCountry\tLanguage\tRating\tDescription' \
    >$SPREADSHEET_FILE
paste $LINK_FILE $SEASONS_FILE $EPISODES_FILE $HEADER_FILE \
    $DESCRIPTION_FILE \
    | nl >>$SPREADSHEET_FILE
if [ "$PRINT_TOTALS" = "yes" ] ; then
	echo -e \
    	"\tTotal\t=SUM(C2:C$lastRow)\t=SUM(D2:E$lastRow)\t\t\t\t\t=COUNTA(I2:I$lastRow)" \
    	>>$SPREADSHEET_FILE
fi

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
    if [ $? == 0 ] ; then
        echo "### -- no diffs found --"
    fi
fi
}
# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS << EOF
==> ${0##*/} completed: `date`

`checkdiffs $MARQUEE_FILE $TITLE_FILE`

`checkdiffs $URL_FILE $PUBLISHED_URLS`
`checkdiffs $MARQUEE_FILE $PUBLISHED_MARQUEES`
`checkdiffs $TITLE_FILE $PUBLISHED_TITLES`
`checkdiffs $LINK_FILE $PUBLISHED_LINKS`
`checkdiffs $DESCRIPTION_FILE $PUBLISHED_DESCRIPTIONS`
`checkdiffs $SEASONS_FILE $PUBLISHED_SEASONS`
`checkdiffs $EPISODES_FILE $PUBLISHED_EPISODES`
`checkdiffs $HEADER_FILE $PUBLISHED_HEADERS`


### Any funny stuff with file lengths? Any differences in
### number of lines indicates the website was updated in the
### middle of processing. You should rerun the script!
`wc $COLUMNS/*$DATE.csv`

EOF

echo
echo "==> ${0##*/} completed: `date`"

