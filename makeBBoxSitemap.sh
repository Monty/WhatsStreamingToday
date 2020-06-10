#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on BritBox

# trap ctrl-c and call cleanup
trap cleanup INT
#
function cleanup() {
    rm -f $TEMP_FILE $TEMP_MISSING_FILE
    echo ""
    exit 130
}

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Create some timestamps
DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# -a ALT picks alternate files to scrape. The triple "BBoxPrograms, BBoxEpisodes, and BBoxSeasons"
#    are amended with ALT, e.g. BBoxPrograms-$ALT.csv, BBoxEpisodes-$ALT.csv, etc.
# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-s" switch to only output a summary. Delete any created files except anomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":a:drst" opt; do
    case $opt in
    a)
        ALT_ID="-$OPTARG"
        DATE_ID="-$OPTARG"
        ;;
    d)
        DEBUG="yes"
        ;;
    s)
        SUMMARY="yes"
        ;;
    t)
        PRINT_TOTALS="yes"
        ;;
    \?)
        echo "[Warning] Ignoring invalid option: -$OPTARG" >&2
        ;;
    :)
        echo "[Error] Option -$OPTARG requires an argument" >&2
        exit 1
        ;;
    esac
done

# Make sure we can execute curl.
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    echo "[Error] Can't run curl. Install curl and rerun this script."
    echo "        To test, type:  curl -Is https://github.com/ | head -5"
    exit 1
fi

# Make sure network is up and BritBox site is reachable
SITEMAP_URL="https://prod-bbc-catalog.s3.amazonaws.com/apple_catalogue_feed.xml"
if ! curl -o /dev/null -Isf $SITEMAP_URL; then
    echo "[Error] $SITEMAP_URL isn't available, or your network is down."
    echo "        Try accessing $SITEMAP_URL in your browser"
    exit 1
fi

COLUMNS="BBox-columns"
BASELINE="BBox-baseline"
SCRAPES="BBox-scrapes"

mkdir -p $COLUMNS $BASELINE $SCRAPES

# File names are used in saveTodaysBBoxFiles.sh
# so if you change them here, change them there as well
# They are named with today's date so running them twice
# in one day will only generate one set of results

# In the default case -- input, output, and baseline files have no date information.
#   but intermediate files have today's date $DATE_ID inserted before the file extension.
# If -a ALT_ID is specified, the $ALT_ID string is instead inserted in ALL of those files,
#   most commonly a LONGDATE corresponding to the original scrape time, but it could
#   be any string.
# Error and debugging files always have a LONGDATE of the execution time inserted.

#
# XML Files to process
SITEMAP_FILE="$SCRAPES/BBox-sitemap.xml"
#
# Final output spreadsheets
SHORT_SPREADSHEET_FILE="BBox_TV_Shows$DATE_ID.csv"
LONG_SPREADSHEET_FILE="BBox_TV_ShowsEpisodes$DATE_ID.csv"
SEASONS_SORTED_SPREADSHEET_FILE="BBoxSeasons-sorted$DATE_ID.csv"
#
# Error and debugging info (per run)
POSSIBLE_DIFFS="BBox_diffs$LONGDATE.txt"
ERROR_FILE="BBox_anomalies$LONGDATE.txt"
EPISODE_INFO_FILE="BBox_episodeInfo$LONGDATE.txt"

# Intermediate but useful results
PROGRAMS_SORTED_FILE="$COLUMNS/BBoxPrograms-sorted$DATE_ID.csv"
EPISODES_SORTED_FILE="$COLUMNS/BBoxEpisodes-sorted$DATE_ID.csv"
SEASONS_SORTED_FILE="$COLUMNS/BBoxSeasons-sorted$DATE_ID.csv"
#
PROGRAMS_SPREADSHEET_FILE="$COLUMNS/BBoxPrograms$DATE_ID.csv"
EPISODES_SPREADSHEET_FILE="$COLUMNS/BBoxEpisodes$DATE_ID.csv"
SEASONS_SPREADSHEET_FILE="$COLUMNS/BBoxSeasons$DATE_ID.csv"
#
# Intermediate working files
PROGRAMS_TITLE_FILE="$COLUMNS/uniqTitlesFrom-BBoxPrograms$DATE_ID.csv"
EPISODES_TITLE_FILE="$COLUMNS/uniqTitlesFrom-BBoxEpisodes$DATE_ID.csv"
DURATION_FILE="$COLUMNS/duration$DATE_ID.csv"
TEMP_FILE="/tmp/BBoxTemp-$DATE_ID.csv"
TEMP_MISSING_FILE="/tmp/BBoxTemp-missing-$DATE_ID.csv"

# Saved files used for comparison with current files
PUBLISHED_SHORT_SPREADSHEET="$BASELINE/spreadsheet$ALT_ID.txt"
PUBLISHED_LONG_SPREADSHEET="$BASELINE/spreadsheetEpisodes$ALT_ID.txt"
PUBLISHED_SEASONS_SORTED_SPREADSHEET="$BASELINE/seasons-sorted$ALT_ID.txt"
#
PUBLISHED_PROGRAMS_SPREADSHEET="$BASELINE/BBoxPrograms$ALT_ID.txt"
PUBLISHED_EPISODES_SPREADSHEET="$BASELINE/BBoxEpisodes$ALT_ID.txt"
PUBLISHED_SEASONS_SPREADSHEET="$BASELINE/BBoxSeasons$ALT_ID.txt"
#
PUBLISHED_DURATION="$BASELINE/duration$ALT_ID.txt"

# Gather filenames that can be used for cleanup
ALL_INTERMEDIATE="$PROGRAMS_SORTED_FILE $EPISODES_SORTED_FILE $SEASONS_SORTED_FILE "
ALL_INTERMEDIATE+="$PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE $DURATION_FILE "
ALL_INTERMEDIATE+="$PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE $SEASONS_SORTED_SPREADSHEET_FILE "
ALL_SPREADSHEETS+="$PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"

# Cleanup any possible leftover files
rm -f $TEMP_FILE $TEMP_MISSING_FILE $DURATION_FILE $SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE \
    $PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE

# Grab the XML file and get rid of Windows CRs
curl -s $SITEMAP_URL | perl -pe 'tr/\r//d' > $SITEMAP_FILE

wc $SITEMAP_FILE
# WARNING - there is a TAB character in the line below
head -4 $SITEMAP_FILE | tail -2 | sed -e 's+</.*++' -e 's+  <++' -e 's+>+	+'
echo "==> ${0##*/} completed: $(date)"
exit

# Generate title files
grep '/us/' $PROGRAMS_SORTED_FILE | cut -f 2 -d $'\t' | sort -u >$PROGRAMS_TITLE_FILE
grep '/us/' $EPISODES_SORTED_FILE | cut -f 5 -d $'\t' | sort -u >$EPISODES_TITLE_FILE

# Print header for verifying episodes across webscraper downloads
# Also prints badEpisodes to TEMP_MISSING_FILE which is used later on
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE
#
awk -v EPISODES_SORTED_FILE=$EPISODES_SORTED_FILE -v SEASONS_SORTED_FILE=$SEASONS_SORTED_FILE \
    -v TEMP_FILE=$TEMP_MISSING_FILE -f verifyBBoxDownloadsFrom-webscraper.awk $PROGRAMS_SORTED_FILE \
    >>$EPISODE_INFO_FILE

# Generate _initial_ spreadsheets from BritBox "Programmes A-Z" page
# Print header about info obtained during processing of shows
printf "### Possible anomalies from processing series are listed below.\n\n" >$ERROR_FILE
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxProgramsFrom-webscraper.awk $PROGRAMS_SORTED_FILE >$PROGRAMS_SPREADSHEET_FILE
printf "\n### Possible anomalies from processing episodes are listed below.\n\n" >>$ERROR_FILE
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxEpisodesFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE
printf "\n### Possible anomalies from processing seasons are listed below.\n\n" >>$ERROR_FILE
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxSeasonsFrom-webscraper.awk $SEASONS_SORTED_FILE >$SEASONS_SPREADSHEET_FILE

# Check for missing titles
printf "In makeBBoxSpreadsheet.sh\n" >&2
missingTitles=$(comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -n '$=')
if [ "$missingTitles" != "" ]; then
    field="title"
    if [ "$missingTitles" != 1 ]; then
        field="titles"
    fi
    printf "    %2d missing %s in $EPISODES_SORTED_FILE\n" "$missingTitles" "$field" >&2
    # Print header for missing episode errors
    printf "\n### Missing titles in $EPISODES_SORTED_FILE are listed below.\n\n" >>$ERROR_FILE
    comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -e 's/^/    /' >>$ERROR_FILE
fi

# badEpisodes were saved in TEMP_MISSING_FILE, if there were none, TEMP_MISSING_FILE won't exist
if [ -e "$TEMP_MISSING_FILE" ]; then
    # Print header for possible errors that occur during processing
    printf "\n### Missing programs in $EPISODES_SORTED_FILE are listed below.\n\n" >>$ERROR_FILE
    sort -df $TEMP_MISSING_FILE >>$ERROR_FILE
    rm -f $TEMP_MISSING_FILE
fi

# Temporarily save a sorted "seasons file" for easier debugging.
# Don't sort header line, keep it at the top of the spreadsheet
# The only difference between the two is the sort order
head -1 $SEASONS_SPREADSHEET_FILE >$SEASONS_SORTED_SPREADSHEET_FILE
grep -hv ^Sortkey $SEASONS_SPREADSHEET_FILE | sort -f >>$SEASONS_SORTED_SPREADSHEET_FILE

# Generate _final_ spreadsheets from BritBox "Programmes A-Z" page
head -1 $PROGRAMS_SPREADSHEET_FILE >$LONG_SPREADSHEET_FILE
grep -hv ^Sortkey $PROGRAMS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE | sort -f |
    tail -r | awk -v ERROR_FILE=$ERROR_FILE -v DURATION_FILE=$DURATION_FILE \
    -f calculateBBoxDurations.awk | tail -r >>$LONG_SPREADSHEET_FILE
#
grep -v ' (2) ' $LONG_SPREADSHEET_FILE >$SHORT_SPREADSHEET_FILE

# Add header for possible crosscheck errors between EPISODES and SEASONS
printf "\n### Any shows with 0 episodes in $EPISODES_FILE or mismatched episodes
### between $SEASONS_FILE and $EPISODES_FILE
### as computed from $EPISODE_INFO_FILE are listed below.\n\n" >>$ERROR_FILE
awk -v REPAIR_SHOWS=$REPAIR_SHOWS -f verifyBBoxInfoFrom-webscraper.awk \
    $EPISODE_INFO_FILE >>$ERROR_FILE

# Shortcut for adding totals to spreadsheets
function addTotalsToSpreadsheet() {
    # Grab (the last) totalTime (just in case)
    totalTime=$(grep : $DURATION_FILE | tail -1)
    ((lastRow = $(sed -n '$=' $1)))
    TOTAL="\tNon-blank values\t=COUNTA(C2:C$lastRow)\t=COUNTA(D2:D$lastRow)\t=COUNTA(E2:E$lastRow)"
    TOTAL+="\t=COUNTA(F2:F$lastRow)\t=COUNTA(G2:G$lastRow)\t=COUNTA(H2:H$lastRow)"
    printf "$TOTAL\n" >>$1
    printf "\tTotal seasons & episodes\t=SUM(C2:C$lastRow)\t=SUM(D2:D$lastRow)\t$totalTime\n" \
        >>$1
}

# Output spreadsheet footer if totals requested
if [ "$PRINT_TOTALS" = "yes" ]; then
    addTotalsToSpreadsheet $SHORT_SPREADSHEET_FILE
    addTotalsToSpreadsheet $LONG_SPREADSHEET_FILE
fi

# If we don't want to create a "diffs" file for debugging, exit here
if [ "$DEBUG" != "yes" ]; then
    if [ "$SUMMARY" = "yes" ]; then
        rm -f $ALL_INTERMEDIATE
        rm -f $ALL_SPREADSHEETS
    fi
    exit
fi

# Shortcut for counting occurrences of a string in all spreadsheets
# countOccurrences string
function countOccurrences() {
    grep -H -c "$1" $ALL_SPREADSHEETS
}

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

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_PROGRAMS_SPREADSHEET $PROGRAMS_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SEASONS_SPREADSHEET $SEASONS_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_EPISODES_SPREADSHEET $EPISODES_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SEASONS_SORTED_SPREADSHEET $SEASONS_SORTED_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_SHORT_SPREADSHEET $SHORT_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_LONG_SPREADSHEET $LONG_SPREADSHEET_FILE)
$(checkdiffs $PUBLISHED_DURATION $DURATION_FILE)

### These counts should not vary much over time
### if they do, the earlier scraping operation may have failed

==> Number of Movies
$(countOccurrences "/us/movie/")

==> Number of Shows
$(countOccurrences "/us/show/")

==> Number of Episodes
$(countOccurrences "/us/episode/")

### Any funny stuff with file lengths?

$(wc $ALL_SPREADSHEETS)

EOF

if [ "$SUMMARY" = "yes" ]; then
    rm -f $ALL_INTERMEDIATE
    rm -f $ALL_SPREADSHEETS
fi

echo
echo "==> ${0##*/} completed: $(date)"
