#! /bin/bash
# Create a .csv spreadsheet of shows available on MHz Networks

# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-l" switch to include every episode description for each series
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
# Use "-u" switch to leave spreadsheet unsorted, i.e. in the order found on the web
while getopts ":dltu" opt; do
    case $opt in
    d)
        DEBUG="yes"
        ;;
    l)
        INCLUDE_EPISODES="yes"
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
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    echo "[Error] Can't run curl. Install curl and rerun this script."
    echo "        To test, type:  curl -Is https://github.com/ | head -5"
    exit 1
fi

# Make sure network is up and MHz Choice site is reachable
# While there are two URLs required at MHz, we only need to check one
BROWSE_URL="https://mhzchoice.vhx.tv/series"
BROWSE_URL2="https://mhzchoice.vhx.tv/series?page=2 https://mhzchoice.vhx.tv/series?page=3"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    echo "[Error] $BROWSE_URL isn't available, or your network is down."
    echo "        Try accessing $BROWSE_URL in your browser"
    exit 1
fi

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

COLUMNS="MHz-columns"
BASELINE="MHz-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveTodaysMHzFiles.sh
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
NUM_SEASONS_FILE="$COLUMNS/numberOfSeasons-$DATE.csv"
PUBLISHED_NUM_SEASONS="$BASELINE/numberOfSeasons.txt"
NUM_EPISODES_FILE="$COLUMNS/numberOfEpisodes-$DATE.csv"
PUBLISHED_NUM_EPISODES="$BASELINE/numberOfEpisodes.txt"
DURATION_FILE="$COLUMNS/durations-$DATE.csv"
PUBLISHED_DURATIONS="$BASELINE/durations.txt"
HEADER_FILE="$COLUMNS/headers-$DATE.csv"
PUBLISHED_HEADERS="$BASELINE/headers.txt"
#
EPISODE_URL_FILE="$COLUMNS/episodeUrls-$DATE.csv"
PUBLISHED_EPISODE_URLS="$BASELINE/episodeUrls.txt"
EPISODE_INFO_FILE="$COLUMNS/episodeInfo-$DATE.csv"
PUBLISHED_EPISODE_INFO="$BASELINE/episodeInfo.txt"
#
if [ "$INCLUDE_EPISODES" = "yes" ]; then
    SPREADSHEET_FILE="MHz_TV_ShowsEpisodes-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
else
    SPREADSHEET_FILE="MHz_TV_Shows-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
fi
#
# Name diffs and errors with both date and time so every run produces a new result
POSSIBLE_DIFFS="MHz_diffs-$LONGDATE.txt"
ERROR_FILE="MHz_anomalies-$LONGDATE.txt"

# Print header for possible errors from processing series
printf "### Possible anomalies from processing series are listed below.\n\n" >$ERROR_FILE

rm -f $URL_FILE $MARQUEE_FILE $TITLE_FILE $LINK_FILE $DESCRIPTION_FILE $NUM_SEASONS_FILE \
    $NUM_EPISODES_FILE $DURATION_FILE $HEADER_FILE $SPREADSHEET_FILE $EPISODE_URL_FILE \
    $EPISODE_INFO_FILE

# Generate series URLs, Titles, Number of Seasons from MHz "Browse" page
curl -sS $BROWSE_URL $BROWSE_URL2 |
    awk -v URL_FILE=$URL_FILE -v TITLE_FILE=$TITLE_FILE \
        -v NUM_SEASONS_FILE=$NUM_SEASONS_FILE -v ERROR_FILE=$ERROR_FILE \
        -f getMHzFrom-browsePage.awk

# keep track of the number of rows in the spreadsheet
lastRow=1
# loop through the list of series URLs from $URL_FILE
while read -r line; do
    # Generate series Marquees, Descriptions, Headers from MHz series pages
    #     (Headers include Genre, Country, Language, Rating)
    # and the list of Episode URLs for further processing.
    curl -sS "$line" |
        awk -v MARQUEE_FILE=$MARQUEE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
            -v HEADER_FILE=$HEADER_FILE -v EPISODE_URL_FILE=$EPISODE_URL_FILE \
            -v ERROR_FILE=$ERROR_FILE -f getMHzFrom-seriesPages.awk
    ((lastRow++))
done <"$URL_FILE"

# keep track of the series number we're processing
currentSeriesNumber=0
# loop through the list of episode URLs from $EPISODE_URL_FILE
while read -r episode_URL; do
    # Control the context of the NUM_EPISODES_FILE when a new series is found
    # Special handling for Don Matteo which starts at season 4
    if [[ ${episode_URL} =~ season:1 || ${episode_URL} =~ "don-matteo/season:4" ]]; then
        ((currentSeriesNumber++))
        if [[ -e $NUM_EPISODES_FILE ]]; then
            echo >>$NUM_EPISODES_FILE
        fi
        echo -n "=" >>$NUM_EPISODES_FILE
    fi
    # Generate a separate file with a line for each episode containing
    # seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
    # episodeTitle, episodeDuration, & episodeDescription with the same columns
    # as the primary spreadsheet so they can be combined into one.
    # Add to the number of episodes in a series but with no terminating newline
    curl -sS "$episode_URL" |
        awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$currentSeriesNumber \
            -v NUM_EPISODES_FILE=$NUM_EPISODES_FILE -v ERROR_FILE=$ERROR_FILE \
            -f getMHzFrom-episodePages.awk
done <"$EPISODE_URL_FILE"
# Add final newline
echo >>$NUM_EPISODES_FILE

# Join the URL and Title into a hyperlink
# WARNING there is an actual tab character in the following command
# because sed in macOS doesn't regognize \t
paste $URL_FILE $TITLE_FILE |
    sed -e 's/^/=HYPERLINK("/; s/	/"\;"/; s/$/")/' >>$LINK_FILE

# Total the duration of all episodes in every series
totalTime=$(awk -v DURATION_FILE=$DURATION_FILE -f calculateDurations.awk $EPISODE_INFO_FILE)

# Output header
printf "#\tTitle\tSeasons\tEpisodes\tDuration\tGenre\tCountry\tLanguage\tRating\tDescription\n" \
    >$SPREADSHEET_FILE
#
# Output body
if [ "$INCLUDE_EPISODES" = "yes" ]; then
    # Print  header for possible errors from processing episodes
    # Don't delete the blank lines!
    cat >>$ERROR_FILE <<EOF1

### Possible anomalies from processing episodes are listed below.
### At least one episode may have no description, but if there are many,
### there could be a temporary problem with the MHz website.
### You can check by using your browser to visit the associated URL.
### You should rerun the script when the problem is cleared up.

EOF1

    # pick a second file to include in the spreadsheet
    file2=$EPISODE_INFO_FILE
    ((lastRow += $(sed -n '$=' $file2)))
else
    # null out included file
    file2=""
fi
#
if [ "$UNSORTED" = "yes" ]; then
    # sort key 1 sorts in the order found on the web
    # sort key 4 sorts by title
    # both sort $file2 by season then episode (if one is provided)
    paste $LINK_FILE $NUM_SEASONS_FILE $NUM_EPISODES_FILE $DURATION_FILE $HEADER_FILE \
        $DESCRIPTION_FILE | awk '{print NR"\t"$0}' | cat - $file2 |
        sort --key=1,1n --key=4 --field-separator=\" >>$SPREADSHEET_FILE
else
    paste $LINK_FILE $NUM_SEASONS_FILE $NUM_EPISODES_FILE $DURATION_FILE $HEADER_FILE \
        $DESCRIPTION_FILE | awk '{print NR"\t"$0}' | cat - $file2 |
        sort --key=4 --field-separator=\" >>$SPREADSHEET_FILE
fi
#
# Output footer
if [ "$PRINT_TOTALS" = "yes" ]; then
    TOTAL="\tNon-blank values\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)"
    TOTAL+="\t=COUNTA(F2:F$lastRow)\t=COUNTA(G2:G$lastRow)\t=COUNTA(H2:H$lastRow)"
    TOTAL+="\t=COUNTA(I2:I$lastRow)\t=COUNTA(J2:J$lastRow)"
    printf "$TOTAL\n" >>$SPREADSHEET_FILE
    printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t$totalTime\n" \
        >>$SPREADSHEET_FILE
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    exit
fi

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs() {
    echo
    if [ ! -e "$1" ]; then
        # If the basefile file doesn't yet exist, assume no differences
        # and copy the newfile to the basefile so it can serve
        # as a base for diffs in the future.
        echo "==> $1 does not exist. Creating it, assuming no diffs."
        cp -p "$2" "$1"
    else
        echo "==> what changed between $1 and $2:"
        # first the stats
        diff -c "$1" "$2" | diffstat -sq \
            -D $(cd $(dirname "$2") && pwd -P) |
            sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
        # then the diffs
        diff \
            --unchanged-group-format='' \
            --old-group-format='==> deleted %dn line%(n=1?:s) at line %df <==
%<' \
            --new-group-format='==> added %dN line%(N=1?:s) after line %de <==
%>' \
            --changed-group-format='==> changed %dn line%(n=1?:s) at line %df <==
%<------ to:
%>' "$1" "$2"
        if [ $? == 0 ]; then
            echo "==> no diffs found"
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

$(checkdiffs $MARQUEE_FILE $TITLE_FILE)


### MHz shows on the web are not sorted by title. When shows are
### rearranged, the individual column diffs may look significant.
### Check the "titles" column diffs to see if the changes are only
### from identical titles being deleted and re-inserted.
$(checkdiffs $PUBLISHED_TITLES $TITLE_FILE)
$(checkdiffs $PUBLISHED_MARQUEES $MARQUEE_FILE)
$(checkdiffs $PUBLISHED_URLS $URL_FILE)
$(checkdiffs $PUBLISHED_LINKS $LINK_FILE)
$(checkdiffs $PUBLISHED_DESCRIPTIONS $DESCRIPTION_FILE)
$(checkdiffs $PUBLISHED_HEADERS $HEADER_FILE)
$(checkdiffs $PUBLISHED_NUM_SEASONS $NUM_SEASONS_FILE)
$(checkdiffs $PUBLISHED_NUM_EPISODES $NUM_EPISODES_FILE)
$(checkdiffs $PUBLISHED_DURATIONS $DURATION_FILE)
$(checkdiffs $PUBLISHED_EPISODE_URLS $EPISODE_URL_FILE)
$(checkdiffs $PUBLISHED_EPISODE_INFO $EPISODE_INFO_FILE)


### Any funny stuff with file lengths? Any differences in
### number of lines indicates the website was updated in the
### middle of processing. You should rerun the script!

$(wc $COLUMNS/*$DATE.csv)

EOF

echo
echo "==> ${0##*/} completed: $(date)"
