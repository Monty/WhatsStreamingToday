#! /bin/bash
# Create a .csv spreadsheet of shows available on BritBox

DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# -a ALT picks alternate files to scrape. The triple "BBoxPrograms, BBoxEpisodes, and BBoxSeasons"
#    are amended with ALT, e.g. BBoxPrograms-$ALT.csv, BBoxEpisodes-$ALT.csv, etc.
# Use "-d" switch to output a "diffs" file useful for debugging
# Use "-s" switch to only output a summary. Delete any created files except anaomalies and info
# Use "-t" switch to print "Totals" and "Counts" lines at the end of the spreadsheet
while getopts ":a:dst" opt; do
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
BROWSE_URL="https://www.britbox.com/us/programmes"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    echo "[Error] $BROWSE_URL isn't available, or your network is down."
    echo "        Try accessing $BROWSE_URL in your browser"
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

# The three input files scraped by webscraper
PROGRAMS_FILE="$SCRAPES/BBoxPrograms$ALT_ID.csv"
if [[ ! -e $PROGRAMS_FILE ]] && [[ $ALT_ID != "" ]]; then
    echo "[Info] Missing PROGRAMS_FILE $PROGRAMS_FILE, using default instead." >&2
    PROGRAMS_FILE="$SCRAPES/BBoxPrograms.csv"
fi
if [ ! -e "$PROGRAMS_FILE" ]; then
    echo "[Error] Missing PROGRAMS_FILE $PROGRAMS_FILE" >&2
    exit 1
fi
EPISODES_FILE="$SCRAPES/BBoxEpisodes$ALT_ID.csv"
if [ ! -e "$EPISODES_FILE" ]; then
    echo "[Error] Missing EPISODES_FILE $EPISODES_FILE" >&2
    exit 1
fi
SEASONS_FILE="$SCRAPES/BBoxSeasons$ALT_ID.csv"
if [ ! -e "$SEASONS_FILE" ]; then
    SEASONS_FILE="/dev/null"
fi
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
TEMP_FILE="/tmp/BBoxTemp$DATE_ID.csv"

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

# ID for scripts & JSON files used to attempt repair of inconsistencies
REPAIR_FILE="repairBBox$LONGDATE.txt"
REPAIR_SCRIPT="repairBBox$LONGDATE.sh"
REPAIR_EPISODES_ID="BBoxEpisodes-repair$LONGDATE"
REPAIR_SEASONS_ID="BBoxSeasons-repair$LONGDATE"

# Gather filenames that can be used for cleanup
ALL_INTERMEDIATE="$PROGRAMS_SORTED_FILE $EPISODES_SORTED_FILE $SEASONS_SORTED_FILE "
ALL_INTERMEDIATE+="$PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE $DURATION_FILE "
ALL_INTERMEDIATE+="$PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"
#
ALL_SPREADSHEETS="$SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE $SEASONS_SORTED_SPREADSHEET_FILE "
ALL_SPREADSHEETS+="$PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE"

# Join broken lines, get rid of useless 'web-scraper-order' field, change comma-separated to
# tab separated, sort into useful order
awk -f fixExtraLinesFrom-webscraper.awk $PROGRAMS_FILE | cut -f 3- -d "," | csvformat -T >$TEMP_FILE
head -1 $TEMP_FILE >$PROGRAMS_SORTED_FILE
grep '/us/' $TEMP_FILE | sort -df --field-separator=$'\t' --key=1,1 \
    >>$PROGRAMS_SORTED_FILE
#
awk -f fixExtraLinesFrom-webscraper.awk $EPISODES_FILE | cut -f 2- -d "," | csvformat -T >$TEMP_FILE
head -1 $TEMP_FILE >$EPISODES_SORTED_FILE
grep '/us/' $TEMP_FILE | sort -df --field-separator=$'\t' --key=1,1 --key=7,7 --key=4,4 \
    >>$EPISODES_SORTED_FILE
#
awk -f fixExtraLinesFrom-webscraper.awk $SEASONS_FILE | cut -f 2- -d "," | csvformat -T >$TEMP_FILE
head -1 $TEMP_FILE >$SEASONS_SORTED_FILE
nfields=$(awk -F\\t '{print NF}' $SEASONS_SORTED_FILE)
sort2=$((nfields - 3))
grep '/us/' $TEMP_FILE | sort -df --field-separator=$'\t' --key=1,1 --key=$sort2,$sort2 --key=3,3 |
    grep -v /us/episode/ >>$SEASONS_SORTED_FILE
#
rm -f $TEMP_FILE

# Print header for verifying episodes across webscraper downloads
printf "### Information on number of episodes and seasons is listed below.\n\n" >$EPISODE_INFO_FILE
#
# Print header for possible missing episode errors
printf "### Missing Program Titles in $EPISODES_SORTED_FILE\n\n" >$ERROR_FILE

grep '/us/' $PROGRAMS_SORTED_FILE | cut -f 2 -d $'\t' | sort -u >$PROGRAMS_TITLE_FILE
grep '/us/' $EPISODES_SORTED_FILE | cut -f 5 -d $'\t' | sort -u >$EPISODES_TITLE_FILE

comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -e 's/^/    /' >>$ERROR_FILE
missingTitles=$(comm -23 $PROGRAMS_TITLE_FILE $EPISODES_TITLE_FILE | sed -n '$=')
if [ "$missingTitles" != "" ]; then
    field="title"
    if [ "$missingTitles" != 1 ]; then
        field="titles"
    fi
    printf "==> %2d missing Program %s in $EPISODES_SORTED_FILE\n" "$missingTitles" "$field" >&2
fi

# Print header for possible errors that occur during processing
printf "\n### /program/ URLs not found in $EPISODES_SORTED_FILE\n\n" >>$ERROR_FILE

rm -f $TEMP_FILE
awk -v EPISODES_SORTED_FILE=$EPISODES_SORTED_FILE -v SEASONS_SORTED_FILE=$SEASONS_SORTED_FILE \
    -v TEMP_FILE=$TEMP_FILE -f verifyBBoxDownloadsFrom-webscraper.awk $PROGRAMS_SORTED_FILE \
    >>$EPISODE_INFO_FILE
sort -df $TEMP_FILE >>$ERROR_FILE
echo "" >>$ERROR_FILE

rm -f $DURATION_FILE $SHORT_SPREADSHEET_FILE $LONG_SPREADSHEET_FILE \
    $PROGRAMS_SPREADSHEET_FILE $SEASONS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE

# Add header about info obtained during processing of shows
printf "\n\n### Information from processing shows is listed below.\n\n" >>$EPISODE_INFO_FILE

# Generate _initial_ spreadsheets from BritBox "Programmes A-Z" page
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxProgramsFrom-webscraper.awk $PROGRAMS_SORTED_FILE >$PROGRAMS_SPREADSHEET_FILE
# Add header for possible errors that occur during processing EPISODES_SORTED_FILE
printf "### Extra /show/ URLs in $EPISODES_SORTED_FILE\n\n" >>$ERROR_FILE
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxEpisodesFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE
# Add header for possible errors that occur during processing SEASONS_SORTED_FILE
printf "\n### Extra /show/ URLs in $SEASONS_SORTED_FILE\n\n" >>$ERROR_FILE
awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
    -f getBBoxSeasonsFrom-webscraper.awk $SEASONS_SORTED_FILE >$SEASONS_SPREADSHEET_FILE

# Temporarily save a sorted "seasons file" for easier debugging.
# Don't sort header line, keep it at the top of the spreadsheet
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
printf "\n### Crosscheck possible errors in $EPISODE_INFO_FILE\n\n" >>$ERROR_FILE
awk -v REPAIR_FILE=$REPAIR_FILE -f verifyBBoxInfoFrom-webscraper.awk $EPISODE_INFO_FILE >>$ERROR_FILE

# Build json files that can be used for repair
grep -B4 startUrl episodeTemplate.json | sed -e "s/BBoxEpisodes/$REPAIR_EPISODES_ID/" \
    >$REPAIR_EPISODES_ID.json
grep -B4 startUrl seasonTemplate.json | sed -e "s/BBoxSeasons/$REPAIR_SEASONS_ID/" \
    >$REPAIR_SEASONS_ID.json
awk -v REPAIR_EPISODES_FILE=$REPAIR_EPISODES_ID.json -v REPAIR_SEASONS_FILE=$REPAIR_SEASONS_ID.json \
    -f buildBBoxRepairScrapers.awk $REPAIR_FILE
grep -B1 -A99 selectors episodeTemplate.json >>$REPAIR_EPISODES_ID.json
grep -B1 -A99 selectors seasonTemplate.json >>$REPAIR_SEASONS_ID.json

# Create a shell script that attempts to repair $EPISODES_FILE
touch $REPAIR_SCRIPT
chmod 755 $REPAIR_SCRIPT
#
# Loop through shows in REPAIR_FILE
# Use FD 3 so you can prompt on STDIN
cat >>$REPAIR_SCRIPT <<EOF
#! /bin/bash
# Interactive repair of $EPISODES_FILE

echo "Attempting to repair shows with possible missing episodes."
echo "You will be given a chance to repair each show individually"
echo "based on comparing the show counts on initial and repaired .csv files."
echo ""
echo "Backups will be saved as $EPISODES_FILE.bak and $SEASONS_FILE.bak"
echo ""

if [ ! -e $SCRAPES/$REPAIR_EPISODES_ID.csv ]; then
    echo "[Error] Can't find $SCRAPES/$REPAIR_EPISODES_ID.csv"
    echo "Create one by scraping with $REPAIR_EPISODES_ID.json"
    exit 1
fi
if [ ! -e $SCRAPES/$REPAIR_SEASONS_ID.csv ]; then
    echo "[Error] can't find $SCRAPES/$REPAIR_SEASONS_ID.csv"
    echo "Create one by scraping with $REPAIR_SEASONS_ID.json"
    exit 1
fi

# Save a backup
cp $EPISODES_FILE $EPISODES_FILE.bak
cp $SEASONS_FILE $SEASONS_FILE.bak

while read -r -u 3 line; do
    echo "### Differences in counts of \$line episodes"
    grep -c \$line $EPISODES_FILE $SCRAPES/$REPAIR_EPISODES_ID.csv
    grep -v \$line $EPISODES_FILE >$TEMP_FILE
    read -r -p "Attempt repair of \$line episodes? [y/N] " YESNO
    if [ "\$YESNO" != "y" ]; then
        echo "Skipping..."
    else
        echo "Repairing ..."
        cp $TEMP_FILE $EPISODES_FILE
        grep \$line $SCRAPES/$REPAIR_EPISODES_ID.csv >> $EPISODES_FILE
    fi
    rm -f $TEMP_FILE
    #
    echo ""
    echo "### Differences in counts of \$line seasons"
    grep -c \$line $SEASONS_FILE $SCRAPES/$REPAIR_SEASONS_ID.csv
    grep -v \$line $SEASONS_FILE >$TEMP_FILE
    read -r -p "Attempt repair of \$line seasons? [y/N] " YESNO
    if [ "\$YESNO" != "y" ]; then
        echo "Skipping..."
    else
        echo "Repairing ..."
        cp $TEMP_FILE $SEASONS_FILE
        grep \$line $SCRAPES/$REPAIR_SEASONS_ID.csv >> $SEASONS_FILE
    fi
    rm -f $TEMP_FILE
    echo ""

done 3<"$REPAIR_FILE"
EOF

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
