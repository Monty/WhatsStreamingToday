#! /bin/bash
# Create a .csv spreadsheet of shows available on Acorn TV

# Use "-c" switch to get a Canadian view of descriptions,
# i.e. don't remove the text "Not available in Canada."
# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-l" switch to include every episode description for each series
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
# Use :-u" switch to leave spreadsheet unsorted, i.e. in the order found on the web
while getopts ":cdltu" opt; do
    case $opt in
    c)
        # Only echo this once, even if -c occurs twice
        if [ -z $IN_CANADA ]; then
            echo "Invoking Canadian version..." >&2
            IN_CANADA="yes"
        fi
        ;;
    d)
        DEBUG="yes"
        ;;
    l)
        INCLUDE_EPISODES="yes"
        echo "NOTICE: The -l option for Acorn TV can take a half hour or more."
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

# Make sure network is up and the Acorn TV site is reachable
BROWSE_URL="https://acorn.tv/browse"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    echo "[Error] $BROWSE_URL isn't available, or your network is down."
    echo "        Try accessing $BROWSE_URL in your browser"
    exit 1
fi

DATE="$(date +%y%m%d)"
LONGDATE="$(date +%y%m%d.%H%M%S)"

COLUMNS="Acorn-columns"
BASELINE="Acorn-baseline"
mkdir -p $COLUMNS $BASELINE

# File names are used in saveTodaysAcornFiles.sh and rebuildAcornBaseline.sh
# so if you change them here, change them there as well. Most are named
# with today's date so running them twice in one day will only generate
# one set of results
CURL_CONFIG_FILE="$COLUMNS/curlConfig-$DATE.csv"
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
#
EPISODE_CURL_FILE="$COLUMNS/episodeCurls-$DATE.csv"
PUBLISHED_EPISODE_CURLS="$BASELINE/episodeCurls.txt"
EPISODE_INFO_FILE="$COLUMNS/episodeInfo-$DATE.csv"
PUBLISHED_EPISODE_INFO="$BASELINE/episodeInfo.txt"
EPISODE_DESCRIPTION_FILE="$COLUMNS/episodeDescription-$DATE.csv"
PUBLISHED_EPISODE_DESCRIPTION="$BASELINE/episodeDescription.txt"
EPISODE_PASTED_FILE="$COLUMNS/episodePasted-$DATE.csv"
PUBLISHED_EPISODE_PASTED="$BASELINE/episodePasted.txt"
#
if [ "$INCLUDE_EPISODES" = "yes" ]; then
    SPREADSHEET_FILE="Acorn_TV_ShowsEpisodes-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheetEpisodes.txt"
else
    SPREADSHEET_FILE="Acorn_TV_Shows-$DATE.csv"
    PUBLISHED_SPREADSHEET="$BASELINE/spreadsheet.txt"
fi
#
# Name diffs and errors with both date and time so every run produces a new result
POSSIBLE_DIFFS="Acorn_diffs-$LONGDATE.txt"
ERROR_FILE="Acorn_anomalies-$LONGDATE.txt"

rm -f $URL_FILE $CURL_CONFIG_FILE $MARQUEE_FILE $TITLE_FILE $LINK_FILE $DESCRIPTION_FILE \
    $NUM_SEASONS_FILE $NUM_EPISODES_FILE $DURATION_FILE $SPREADSHEET_FILE \
    $EPISODE_CURL_FILE $EPISODE_INFO_FILE $EPISODE_DESCRIPTION_FILE \
    $EPISODE_PASTED_FILE

curl -sS $BROWSE_URL |
    awk -v URL_FILE=$URL_FILE -v CURL_CONFIG_FILE=$CURL_CONFIG_FILE \
        -v MARQUEE_FILE=$MARQUEE_FILE -f getAcornFrom-browsePage.awk

# Print header for possible errors from processing series
echo -e "### Possible anomalies from processing series are listed below.\n" >$ERROR_FILE

# keep track of the number of rows in the spreadsheet
lastRow=1
# loop through the list of series URLs from $CURL_CONFIG_FILE
# Create column files with lists of series titles, descriptions, number
# of seasons, and number of episodes, to be pasted into the spreadsheet.
# Note that IN_CANADA affects processing.
#
# Create a separate file with a line for each episode containing
# seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
# episodeTitle, & episodeDuration with the same columns as the primary
# spreadsheet so they can be combined into one.
totalTime=$(curl -sS --config $CURL_CONFIG_FILE |
    awk -v TITLE_FILE=$TITLE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
        -v NUM_SEASONS_FILE=$NUM_SEASONS_FILE -v NUM_EPISODES_FILE=$NUM_EPISODES_FILE \
        -v EPISODE_CURL_FILE=$EPISODE_CURL_FILE -v IN_CANADA=$IN_CANADA \
        -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$lastRow \
        -v DURATION_FILE=$DURATION_FILE -v ERROR_FILE=$ERROR_FILE -f getAcornFrom-seriesPages.awk)
((lastRow += $(sed -n '$=' $TITLE_FILE)))

if [ "$INCLUDE_EPISODES" = "yes" ]; then
    # Print  header for possible errors from processing episodes
    # Don't delete the blank lines!
    cat >>$ERROR_FILE <<EOF1

### Possible anomalies from processing episodes are listed below.
### At least one episode may have no description, but if there are many,
### there could be a temporary problem with the Acorn website.
### You can check by using your browser to visit the associated URL.
### You should rerun the script when the problem is cleared up.

EOF1

    episodeNumber=1
    # loop through the list of episode URLs from $EPISODE_CURL_FILE
    # WARNING can take an hour or more
    # Generate a separate file with a line for each episode containing
    # the description of that episode
    curl -sS --config $EPISODE_CURL_FILE |
        awk -v EPISODE_DESCRIPTION_FILE=$EPISODE_DESCRIPTION_FILE \
            -v ERROR_FILE=$ERROR_FILE -v EPISODE_CURL_FILE=$EPISODE_CURL_FILE \
            -v EPISODE_NUMBER=$episodeNumber -f getAcornFrom-episodePages.awk
    paste $EPISODE_INFO_FILE $EPISODE_DESCRIPTION_FILE >$EPISODE_PASTED_FILE
    # pick a second file to include in the spreadsheet
    file2=$EPISODE_PASTED_FILE
    ((lastRow += $(sed -n '$=' $file2)))
else
    # null out included file
    file2=""
fi

# Join the URL and Title into a hyperlink
# WARNING there is an actual tab character in the following command
# because sed in macOS doesn't regognize \t
paste $URL_FILE $TITLE_FILE |
    sed -e 's/^/=HYPERLINK("/; s/	/"\;"/; s/$/")/' >>$LINK_FILE

# Output header
echo -e "#\tTitle\tSeasons\tEpisodes\tDuration\tDescription" >$SPREADSHEET_FILE
#
# Output body
if [ "$UNSORTED" = "yes" ]; then
    # sort key 1 sorts in the order found on the web
    # sort key 4 sorts by title
    # both sort $file2 by season then episode (if one is provided)
    paste $LINK_FILE $NUM_SEASONS_FILE $NUM_EPISODES_FILE $DURATION_FILE \
        $DESCRIPTION_FILE | nl -n ln | cat - $file2 |
        sort --key=1,1n --key=4 --field-separator=\" >>$SPREADSHEET_FILE
else
    paste $LINK_FILE $NUM_SEASONS_FILE $NUM_EPISODES_FILE $DURATION_FILE \
        $DESCRIPTION_FILE | nl -n ln | cat - $file2 |
        sort --key=4 --field-separator=\" >>$SPREADSHEET_FILE
fi
#
# Output footer
if [ "$PRINT_TOTALS" = "yes" ]; then
    echo -e \
        "\tNon-blank values\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)\
        \t=COUNTA(F2:F$lastRow)" >>$SPREADSHEET_FILE
    echo -e "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t$totalTime" \
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
    if [ ! -e "$2" ]; then
        echo "==> $2 does not exist. Skipping diff."
        return 1
    fi
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
cat >>$POSSIBLE_DIFFS <<EOF2
==> ${0##*/} completed: $(date)

### Differences between the titles found in two places on the Acorn website
### are listed below. These are not our problem though.

$(checkdiffs $MARQUEE_FILE $TITLE_FILE)

### Differences between saved Acorn-baseline and current Acorn-columns files
### are listed below.

$(checkdiffs $PUBLISHED_TITLES $TITLE_FILE)
$(checkdiffs $PUBLISHED_MARQUEES $MARQUEE_FILE)
$(checkdiffs $PUBLISHED_URLS $URL_FILE)
$(checkdiffs $PUBLISHED_LINKS $LINK_FILE)
$(checkdiffs $PUBLISHED_DESCRIPTIONS $DESCRIPTION_FILE)
$(checkdiffs $PUBLISHED_NUM_SEASONS $NUM_SEASONS_FILE)
$(checkdiffs $PUBLISHED_NUM_EPISODES $NUM_EPISODES_FILE)
$(checkdiffs $PUBLISHED_DURATIONS $DURATION_FILE)
$(checkdiffs $PUBLISHED_EPISODE_CURLS $EPISODE_CURL_FILE)
$(checkdiffs $PUBLISHED_EPISODE_INFO $EPISODE_INFO_FILE)


### Any funny stuff with file lengths? There should only
### be two different lengths. Any differences in the number
### of lines indicates the website was updated in the
### middle of processing. You should rerun the script!

$(wc $COLUMNS/*$DATE.csv)

EOF2

echo
echo "==> ${0##*/} completed: $(date)"
