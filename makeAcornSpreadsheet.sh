#! /bin/bash
# Create a .csv spreadsheet of shows available on Acorn TV

# Use "-c" switch to get a Canadian view of descriptions,
# i.e. don't remove the text "Not available in Canada."
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
# Use :-u" switch to leave spreadsheet unsorted, i.e. in the order found on the web
while getopts ":ctu" opt; do
    case $opt in
        c)
            # Only echo this once, even if -c occurs twice
            if [ -z $IN_CANADA ] ; then
                echo "Invoking Canadian version..." >&2
                IN_CANADA="yes"
            fi
            ;;
        t)
            PRINT_TOTALS="yes"
            ;;
        u)
            UNSORTED="yes"
            ;;
        \?)
            echo "Ignoring invalid option: -$OPTARG" >&2
            ;;
    esac
done

# Make sure we can execute curl.
if [ ! -x "$(which curl 2>/dev/null)" ] ; then
    echo "[Error] Can't run curl. Install curl and rerun this script."
    echo "        To test, type:  curl -Is https://github.com/ | head -5"
    exit 1
fi

# Make sure network is up and the Acorn TV site is reachable
BASE_URL="https://acorn.tv/browse"
if ! curl -o /dev/null -Isf $BASE_URL ; then
    echo "[Error] $BASE_URL isn't available, or your network is down."
    echo "        Try accessing $BASE_URL in your browser"
    exit 1
fi

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveLatestAcornFiles.sh
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
#
SPREADSHEET_FILE="Acorn_TV_Shows-$DATE.csv"
PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
#
# Name diffs with both date and time so every run produces a new result
POSSIBLE_DIFFS="Acorn_diffs-$LONGDATE.txt"

rm -f $URL_FILE $MARQUEE_FILE $TITLE_FILE $LINK_FILE $DESCRIPTION_FILE \
    $SEASONS_FILE $EPISODES_FILE $SPREADSHEET_FILE

curl -s $BASE_URL \
    | awk -v URL_FILE=$URL_FILE -v MARQUEE_FILE=$MARQUEE_FILE -f fetchAcorn-series.awk

# keep track of the last spreadsheet row containing data
lastRow=1
while read line
do
    ((lastRow++))
    curl -s $line \
        | awk -v TITLE_FILE=$TITLE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
            -v SEASONS_FILE=$SEASONS_FILE -v EPISODES_FILE=$EPISODES_FILE \
            -v IN_CANADA=$IN_CANADA -f fetchAcorn-episodes.awk
done < "$URL_FILE"

# Join the URL and Title into a hyperlink
# WARNING there is an actual tab character in the following command
# because sed in macOS doesn't regognize \t
paste $URL_FILE $TITLE_FILE \
    | sed -e 's/^/=HYPERLINK("/; s/	/"\;"/; s/$/")/' >>$LINK_FILE

echo -e "Title\tSeasons\tEpisodes\tDescription" >$SPREADSHEET_FILE
if [ "$UNSORTED" = "yes" ] ; then
    paste $LINK_FILE $SEASONS_FILE $EPISODES_FILE \
        $DESCRIPTION_FILE >>$SPREADSHEET_FILE
else
    paste $LINK_FILE $SEASONS_FILE $EPISODES_FILE \
        $DESCRIPTION_FILE | sort --key=2  --field-separator=\; >>$SPREADSHEET_FILE
fi
if [ "$PRINT_TOTALS" = "yes" ] ; then
    echo -e \
"Non-blank values\t=COUNTA(B2:B$lastRow)\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)" \
        >>$SPREADSHEET_FILE
    echo -e "Total seasons & episodes\t=SUM(B2:B$lastRow)\t=SUM(C2:C$lastRow)" \
        >>$SPREADSHEET_FILE
fi

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs () {
echo
if [ ! -e "$1" ] ; then
    # If the basefile file doesn't yet exist, assume no differences
    # and copy the newfile to the basefile so it can serve
    # as a base for diffs in the future.
    echo "==> $1 does not exist. Creating it, assuming no diffs."
    cp -p $2 $1
else
    echo "### diff $1 $2"
    diff \
        --unchanged-group-format='' \
        --old-group-format='### %dn line%(n=1?:s) deleted at %df:
%<' \
        --new-group-format='### %dN line%(N=1?:s) added after %de:
%>' \
        --changed-group-format='### %dn line%(n=1?:s) changed at %df:
%<------ to:
%>' $1 $2
    if [ $? == 0 ] ; then
        echo "### -- no diffs found --"
    fi
fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS << EOF
==> ${0##*/} completed: $(date)

$(checkdiffs $MARQUEE_FILE $TITLE_FILE)

$(checkdiffs $PUBLISHED_URLS $URL_FILE)
$(checkdiffs $PUBLISHED_MARQUEES $MARQUEE_FILE)
$(checkdiffs $PUBLISHED_TITLES $TITLE_FILE)
$(checkdiffs $PUBLISHED_LINKS $LINK_FILE)
$(checkdiffs $PUBLISHED_DESCRIPTIONS $DESCRIPTION_FILE)
$(checkdiffs $PUBLISHED_SEASONS $SEASONS_FILE)
$(checkdiffs $PUBLISHED_EPISODES $EPISODES_FILE)

$(checkdiffs $PUBLISHED_SPREADSHEET $SPREADSHEET_FILE)


### Any funny stuff with file lengths? Any differences in
### number of lines indicates the website was updated in the
### middle of processing. You should rerun the script!

$(wc $COLUMNS/*$DATE.csv)

EOF

echo
echo "==> ${0##*/} completed: $(date)"

