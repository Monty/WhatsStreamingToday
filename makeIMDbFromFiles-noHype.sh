#!/usr/bin/env bash
#
# Generate show and cast spreadsheets from:
#   1) .tconst file(s) containing a list of IMDb tconst identifiers
#
#       See https://www.imdb.com/interfaces/ for a description of IMDb Datasets
#       tconst (string) - alphanumeric unique identifier of the title
#
#       For example:
#           tt3582458
#           tt7684260
#           tt2980074
#           ...
#
#       Defaults to all .tconst files, or specify them on the command line
#
#    2) .xlate file(s) with tab separated pairs of non-English titles and their English equivalents
#
#       For example:
#           Den fördömde	Sebastian Bergman
#           Der Bestatter	The Undertaker
#
#       Defaults to all .xlate files, or specify one with -t [file] on the command line
#

# trap ctrl-c and call cleanup
trap cleanup INT
#
function cleanup() {
    printf "\n"
    exit 130
}

breakpoint() {
    if [ "$DEBUG" == "yes" ]; then
        read -r -p "Quit now? [y/N] " YESNO
        if [ "$YESNO" == "y" ]; then
            printf "Quitting ...\n"
            exit 1
        fi
    fi
}

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Make sort consistent between Mac and Linux
export LC_COLLATE="C"

# Default translation files to all .xlate files, but allow user to override
XLATE_FILES="*.xlate"
while getopts ":t:dh" opt; do
    case $opt in
    h)
        printf "Create spreadsheets of shows, actors, and the characters they portray\n"
        printf "from downloaded IMDb .gz fies. See https://www.imdb.com/interfaces/\n\n"
        printf "USAGE:\n"
        printf "    ./makeIMDbFromFiles.sh [-t translation file] [tconst file ...]\n"
        exit
        ;;
    d)
        DEBUG="yes"
        ;;

    t)
        XLATE_FILES="$OPTARG"
        ;;
    \?)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    :)
        printf "Option -$OPTARG requires a 'translation file' argument'.\n" >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# Make sure we can execute rg.
if [ ! -x "$(which rg 2>/dev/null)" ]; then
    printf "[Error] Can't run rg. Install rg and rerun this script.\n"
    printf "        zgrep could be used, but is 15x slower in my tests.\n"
    printf "        See https://crates.io/crates/ripgrep for details.\n"
    exit 1
fi

# Make sure we have downloaded the IMDb files
if [ -e "name.basics.tsv.gz" ] && [ -e "title.basics.tsv.gz" ] && [ -e "title.principals.tsv.gz" ] &&
    [ -e "title.episode.tsv.gz" ]; then
    printf "==> Using existing IMDb .gz files.\n"
else
    printf "==> Downloading new IMDb .gz files.\n"
    # Make sure we can execute curl.
    if [ ! -x "$(which curl 2>/dev/null)" ]; then
        printf "[Error] Can't run curl. Install curl and rerun this script.\n"
        printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
        exit 1
    fi
    for file in name.basics.tsv.gz title.basics.tsv.gz title.episode.tsv.gz title.principals.tsv.gz; do
        if [ ! -e "$file" ]; then
            source="https://datasets.imdbws.com/$file"
            printf "Downloading $source\n"
            curl -s -O $source
        fi
    done
fi
printf "\n"

# Let us know which title translation files are used.
if [ "$XLATE_FILES" == "*.xlate" ]; then
    printf "==> Using all .xlate files for IMDb title translation.\n\n"
else
    printf "==> Using $XLATE_FILES for IMDb title translation.\n\n"
fi
if [ ! "$(ls $XLATE_FILES 2>/dev/null)" ]; then
    printf "==> [Error] No such file: $XLATE_FILES\n"
    exit 1
fi

# Pick tconst file(s) to process
if [ $# -eq 0 ]; then
    TCONST_FILES="*.tconst"
    printf "==> Searching all .tconst files for IMDb title identifiers.\n"
else
    TCONST_FILES="$@"
    printf "==> Searching $TCONST_FILES for IMDb title identifiers.\n"
fi
if [ ! "$(ls $TCONST_FILES 2>/dev/null)" ]; then
    if [ $# -ge 2 ]; then
        PLURAL="s"
    fi
    printf "==> [Error] No such file$PLURAL: $TCONST_FILES\n"
    exit 1
fi

# Create some timestamps
DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# Required subdirectories
COLS="IMDb-columns"
BASELINE="IMDb-baseline"
mkdir -p $COLS $BASELINE

# Error and debugging info (per run)
POSSIBLE_DIFFS="IMDb_diffs-noHype$LONGDATE.txt"
ERRORS="IMDb_anomalies-noHype$LONGDATE.txt"

# Final output spreadsheets
CREDITS_SHOW="IMDb_Credits-Show-noHype$DATE_ID.csv"
CREDITS_PERSON="IMDb_Credits-Person-noHype$DATE_ID.csv"
PERSONS="IMDb_Persons-Titles-noHype$DATE_ID.csv"
SHOWS="IMDb_Shows-noHype$DATE_ID.csv"
ASSOCIATED_TITLES="IMDb_associatedTitles-noHype$DATE_ID.csv"

# Final output lists
UNIQUE_PERSONS="IMDb_uniqPersons-noHype$DATE_ID.txt"
UNIQUE_TITLES="IMDb_uniqTitles-noHype$DATE_ID.txt"

# Intermediate working files
DUPES="$COLS/dupes-noHype$DATE_ID.txt"
CONFLICTS="$COLS/conflicts-noHype$DATE_ID.txt"
TCONST_ALL="$COLS/tconst_all-noHype$DATE_ID.txt"
TCONST_LIST="$COLS/tconst-noHype$DATE_ID.txt"
EPISODES_LIST="$COLS/tconst-episodes-noHype$DATE_ID.txt"
KNOWNFOR_LIST="$COLS/tconst_known-noHype$DATE_ID.txt"
NCONST_LIST="$COLS/nconst-noHype$DATE_ID.txt"
RAW_SHOWS="$COLS/raw_shows-noHype$DATE_ID.csv"
RAW_EPISODES="$COLS/raw_episodes-noHype$DATE_ID.csv"
RAW_PERSONS="$COLS/raw_persons-noHype$DATE_ID.csv"
UNSORTED_CREDITS="$COLS/unsorted_credits-noHype$DATE_ID.csv"
UNSORTED_EPISODES="$COLS/unsorted_episodes-noHype$DATE_ID.csv"
#
TCONST_SHOWS_PL="$COLS/tconst-shows-pl-noHype$DATE_ID.txt"
TCONST_EPISODES_PL="$COLS/tconst-episodes-pl-noHype$DATE_ID.txt"
TCONST_EPISODE_NAMES_PL="$COLS/tconst-episode_names-pl-noHype$DATE_ID.txt"
TCONST_KNOWN_PL="$COLS/tconst-known-pl-noHype$DATE_ID.txt"
NCONST_PL="$COLS/nconst-pl-noHype$DATE_ID.txt"
XLATE_PL="$COLS/xlate-pl-noHype$DATE_ID.txt"

# Manually entered list of tconst ID's that we don't want tvEpisodes for
# either because they have too many episodes, or the episodes don't translate well
SKIP_EPISODES="skipEpisodes.TCONST"
SKIP_TCONST="$COLS/tconst-skip$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_SKIP_EPISODES="$BASELINE/skipEpisodes.TCONST"
PUBLISHED_CREDITS_SHOW="$BASELINE/credits-show-noHype.csv"
PUBLISHED_CREDITS_PERSON="$BASELINE/credits-person-noHype.csv"
PUBLISHED_PERSONS="$BASELINE/persons-titles-noHype.csv"
PUBLISHED_SHOWS="$BASELINE/shows-noHype.csv"
PUBLISHED_ASSOCIATED_TITLES="$BASELINE/associatedTitles-noHype.csv"
#
PUBLISHED_UNIQUE_PERSONS="$BASELINE/uniqPersons-noHype.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles-noHype.txt"
#
PUBLISHED_TCONST_ALL="$BASELINE/tconst_all-noHype.txt"
PUBLISHED_TCONST_LIST="$BASELINE/tconst-noHype.txt"
PUBLISHED_EPISODES_LIST="$BASELINE/tconst-episodes-noHype.csv"
PUBLISHED_KNOWNFOR_LIST="$BASELINE/tconst_known-noHype.txt"
PUBLISHED_NCONST_LIST="$BASELINE/nconst-noHype.txt"
PUBLISHED_RAW_SHOWS="$BASELINE/raw_shows-noHype.csv"
PUBLISHED_RAW_PERSONS="$BASELINE/raw_persons-noHype.csv"

# Filename groups used for cleanup
ALL_WORKING="$CONFLICTS $DUPES $SKIP_TCONST $TCONST_LIST $TCONST_ALL $NCONST_LIST "
ALL_WORKING+="$EPISODES_LIST $KNOWNFOR_LIST $XLATE_PL $TCONST_SHOWS_PL "
ALL_WORKING+="$NCONST_PL $TCONST_EPISODES_PL $TCONST_EPISODE_NAMES_PL $TCONST_KNOWN_PL"
ALL_TXT="$UNIQUE_TITLES $UNIQUE_PERSONS"
ALL_CSV="$RAW_SHOWS $RAW_PERSONS $UNSORTED_CREDITS $UNSORTED_EPISODES"
ALL_SPREADSHEETS="$SHOWS $PERSONS $CREDITS_SHOW $CREDITS_PERSON $ASSOCIATED_TITLES"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_TXT $ALL_CSV $ALL_SPREADSHEETS

[ "$DEBUG" == "yes" ] && set -v
# Create a master tconst_all
rg -IN "^tt" *.tconst | cut -f 1 | sort -u >$TCONST_ALL
# Coalesce a single tconst input list
rg -IN "^tt" $TCONST_FILES | cut -f 1 | sort -u >$TCONST_LIST

# Create a perl "substitute" script to translate any known non-English titles to their English equivalent
# Regex delimiter needs to avoid any characters present in the input, use {} for readability
rg -INv -e "^#" -e "^$" $XLATE_FILES | cut -f 1,2 | sort -fu |
    perl -p -e 's+\t+\\t}\{\\t+; s+^+s{\\t+; s+$+\\t};+' >$XLATE_PL

# Generate a csv of titles from the tconst list, remove the "adult" field,
# translate any known non-English titles to their English equivalent,
TAB=$(printf "\t")
rg -wNz -f $TCONST_LIST title.basics.tsv.gz | cut -f 1-4,6-9 | perl -p -f $XLATE_PL |
    perl -p -e 's+\t+\t\t\t+;' | tee $RAW_SHOWS | cut -f 5 | sort -fu >$UNIQUE_TITLES

# Check for translation conflicts
rg -INv -e "^#" -e "^$" $XLATE_FILES | cut -f 1 | sort -f | uniq -d >$DUPES

rg -IN -f $DUPES $XLATE_FILES | sort -fu | cut -f 1 | sort -f | uniq -d >$CONFLICTS
cut -f 6 $RAW_SHOWS | sort -f | uniq -d >>$CONFLICTS
if [ -s $CONFLICTS ]; then
    printf "\n==> [Error] Translation conflicts are listed below. Fix them then rerun this script.\n"
    printf "\n==> These shows have more than one tconst.\n"
    rg -H -f $CONFLICTS $RAW_SHOWS
    printf "\n"
    printf "==> Make sure to delete corresponding lines in Episode.tconst and Episode.xlate.\n"
    rg -f $CONFLICTS $XLATE_FILES $TCONST_FILES
    printf "\n"
    exit 1
fi

# We don't want to check for episodes in any tvSeries that has hundreds of tvEpisodes
# or that has episodes with titles that aren't unique like "Episode 1" that can't be "translated"
# back to the original show. Manually maintain a skip list in $SKIP_EPISODES.
rg -v -e "^#" -e "^$" $SKIP_EPISODES | cut -f 1 >$SKIP_TCONST

# Let us know what shows we're processing - format for readability, separate with ";"
num_titles=$(sed -n '$=' $UNIQUE_TITLES)
printf "\n==> Processing $num_titles shows found in $TCONST_FILES:\n"
perl -p -e 's+$+;+' $UNIQUE_TITLES | fmt -w 80 | perl -p -e 's+^+\t+' | sed '$ s+.$++'

# Use the tconst list to lookup episode IDs and generate an episode tconst file
rg -wNz -f $TCONST_LIST title.episode.tsv.gz | perl -p -e 's+\\N++g;' |
    sort -f --field-separator="$TAB" --key=2,2 --key=3,3n --key=4,4n | rg -wv -f $SKIP_TCONST |
    tee $UNSORTED_EPISODES | cut -f 1 >$EPISODES_LIST

# Use the episodes list to generate raw episodes
rg -wNz -f $EPISODES_LIST title.basics.tsv.gz | cut -f 1-4,6-9 | perl -p -f $XLATE_PL |
    perl -p -e 's+\\N++g;' | sort -f --field-separator="$TAB" --key=3,3 --key=5,5 --key=4,4 >$RAW_EPISODES

# Use the tconst list to lookup principal titles and generate a tconst/nconst credits csv
# Fix bogus nconst nm0745728, it should be nm0745694. Rearrange fields
rg -wNz -f $TCONST_LIST title.principals.tsv.gz | rg -w -e actor -e actress -e writer -e director |
    sort --key=1,1 --key=2,2n | perl -p -e 's+nm0745728+nm0745694+' | perl -p -e 's+\\N++g;' |
    perl -F"\t" -lane 'printf "%s\t%s\t\t%02d\t%s\t%s\n", @F[2,0,1,3,5]' | tee $UNSORTED_CREDITS |
    cut -f 1 | sort -u >$NCONST_LIST

# Use the episodes list to lookup principal titles and add to the tconst/nconst credits csv
rg -wNz -f $EPISODES_LIST title.principals.tsv.gz | rg -w -e actor -e actress -e writer -e director |
    sort --key=1,1 --key=2,2n | perl -p -e 's+\\N++g;' |
    perl -F"\t" -lane 'printf "%s\t%s\t%s\t%02d\t%s\t%s\n", @F[2,0,0,1,3,5]' | tee -a $UNSORTED_CREDITS |
    cut -f 1 | sort -u | rg -v -f $NCONST_LIST >>$NCONST_LIST

# Create a perl script to globally convert a show tconst to a show title
cut -f 1,5 $RAW_SHOWS | perl -F"\t" -lane 'print "s{\\b@F[0]\\b}\{'\''@F[1]}g;";' >$TCONST_SHOWS_PL

# Create a perl script to convert an episode tconst to its parent show title
perl -F"\t" -lane 'print "s{\\b@F[0]\\b}\{@F[1]\\t@F[2]\\t@F[3]};";' $UNSORTED_EPISODES |
    perl -p -f $TCONST_SHOWS_PL >$TCONST_EPISODES_PL

# Create a perl script to convert an episode tconst to its episode title
perl -F"\t" -lane 'print "s{\\b@F[0]\\b}\{'\''@F[2]};";' $RAW_EPISODES >$TCONST_EPISODE_NAMES_PL

# Convert raw episodes to raw shows
perl -pi -f $TCONST_EPISODES_PL $RAW_EPISODES

# Remove extra tab fields from $TCONST_EPISODES_PL
perl -pi -e 's/\\t.*}/}/' $TCONST_EPISODES_PL

# Create a perl script to convert an nconst to a name
rg -wNz -f $NCONST_LIST name.basics.tsv.gz | perl -p -e 's+\\N++g;' | cut -f 1-2,6 | sort -fu --key=2 |
    tee $RAW_PERSONS | perl -F"\t" -lane 'print "s{^@F[0]\\b}\{@F[1]};";' >$NCONST_PL

# Get rid of ugly \N fields, unneeded characters, and make sure commas are followed by spaces
perl -pi -e 's+\\N++g; tr+"[]++d; s+,+, +g; s+,  +, +g;' $ALL_CSV

# Create the PERSONS spreadsheet
printf "Person\tKnown For Titles: 1\tKnown For Titles: 2\tKnown For Titles: 3\tKnown For Titles: 4\n" \
    >$PERSONS
cut -f 1,3 $RAW_PERSONS | perl -p -e 's+, +\t+g' >>$PERSONS

# Create a tconst list of the knownForTitles
cut -f 3 $RAW_PERSONS | rg "^tt" | perl -p -e 's+, +\n+g' | sort -u >$KNOWNFOR_LIST

# Create a perl script to globally convert a known show tconst to a show title
rg -wNz -f $KNOWNFOR_LIST title.basics.tsv.gz | perl -p -f $XLATE_PL | cut -f 1,3 |
    perl -F"\t" -lane 'print "s{\\b@F[0]\\b}\{'\''@F[1]}g;";' >$TCONST_KNOWN_PL

# Create a spreadsheet of associated titles gained from IMDb knownFor data
printf "tconst\tShow Title\n" >$ASSOCIATED_TITLES
perl -p -e 's+^.*btt+tt+; s+\\b}\{+\t+; s+}.*++;' $TCONST_KNOWN_PL |
    perl -F"\t" -lane 'print "@F[0]\t@F[1]";' | sort -fu --field-separator="$TAB" --key=2,2 |
    rg -wv -f $TCONST_ALL >>$ASSOCIATED_TITLES

# Add episodes into raw shows
perl -p -f $TCONST_EPISODES_PL $RAW_EPISODES >>$RAW_SHOWS

# Translate tconst and nconst into titles and names
perl -pi -f $TCONST_SHOWS_PL $RAW_SHOWS
perl -pi -f $TCONST_SHOWS_PL $UNSORTED_CREDITS
perl -pi -f $TCONST_EPISODES_PL $UNSORTED_CREDITS
perl -pi -f $TCONST_EPISODE_NAMES_PL $UNSORTED_CREDITS
perl -pi -f $NCONST_PL $UNSORTED_CREDITS
perl -pi -f $TCONST_KNOWN_PL $PERSONS
perl -pi -f $NCONST_PL $PERSONS

# Create UNIQUE_PERSONS
cut -f 2 $RAW_PERSONS | sort -fu >$UNIQUE_PERSONS

# Create the SHOWS spreadsheet by removing duplicate field from RAW_SHOWS
printf "Show Title\tShow Type\tOriginal or Episode Title\tSn_#\tEp_#\tStart\tEnd\tMinutes\tGenres\n" >$SHOWS
# Sort by Show Title (1), Show Type (2r), Sn_# (4n), Ep_# (5n), Start (6)
perl -F"\t" -lane 'printf "%s\t%s\t'\''%s\t%s\t%s\t%s\t%s\t%s\t%s\n", @F[0,3,5,1,2,6,7,8,9]' $RAW_SHOWS |
    sort -f --field-separator="$TAB" --key=1,1 --key=2,2r --key=4,4n --key=5,5n --key=6,6 >>$SHOWS

# Create the sorted CREDITS spreadsheets
printf "Person\tShow Title\tEpisode Title\tRank\tJob\tCharacter Name\n" | tee $CREDITS_SHOW >$CREDITS_PERSON
# Sort by Person (1), Show Title (2), Rank (4), Episode Title (3)
sort -f --field-separator="$TAB" --key=1,2 --key=4,4 --key=3,3 $UNSORTED_CREDITS >>$CREDITS_PERSON
# Sort by Show Title (2), Episode Title (3), Rank (4)
sort -f --field-separator="$TAB" --key=2,4 $UNSORTED_CREDITS >>$CREDITS_SHOW

[ "$DEBUG" == "yes" ] && set -

# Shortcut for printing file info (before adding totals)
function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    numlines=$(($(sed -n '$=' $1) - $2))
    ls -loh $1 | perl -lane 'printf "%-45s%6s%6s %s %s ",@F[7,3,4,5,6];'
    printf "%8d lines\n" "$numlines"
}

# Output some stats from $SHOWS
printf "\n==> Show types in $SHOWS:\n"
cut -f 4 $RAW_SHOWS | sort | uniq -c | sort -nr | perl -p -e 's+^+\t+'

# Output some stats from credits
printf "\n==> Stats from processing $CREDITS_PERSON:\n"
numPersons=$(sed -n '$=' $UNIQUE_PERSONS)
printf "%8d people credited -- some in more than one job function\n" "$numPersons"
for i in actor actress writer director; do
    count=$(cut -f 1,5 $UNSORTED_CREDITS | sort -fu | rg -cw "$i$")
    printf "%13d as %s\n" "$count" "$i"
done

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from processing IMDb data:\n"
printAdjustedFileInfo $UNIQUE_TITLES 0
# printAdjustedFileInfo $TCONST_LIST 0
# printAdjustedFileInfo $RAW_SHOWS 0
printAdjustedFileInfo $SHOWS 1
# printAdjustedFileInfo $NCONST_LIST 0
printAdjustedFileInfo $UNIQUE_PERSONS 0
# printAdjustedFileInfo $RAW_PERSONS 0
printAdjustedFileInfo $PERSONS 1
printAdjustedFileInfo $CREDITS_SHOW 1
printAdjustedFileInfo $CREDITS_PERSON 1
printAdjustedFileInfo $ASSOCIATED_TITLES 1
# printAdjustedFileInfo $KNOWNFOR_LIST 0

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs() {
    printf "\n"
    if [ ! -e "$2" ]; then
        printf "==> $2 does not exist. Skipping diff.\n"
        return 1
    fi
    if [ ! -e "$1" ]; then
        # If the basefile file doesn't yet exist, assume no differences
        # and copy the newfile to the basefile so it can serve
        # as a base for diffs in the future.
        printf "==> $1 does not exist. Creating it, assuming no diffs.\n"
        cp -p "$2" "$1"
    else
        # first the stats
        printf "./whatChanged \"$1\" \"$2\"\n"
        diff -u "$1" "$2" | diffstat -sq \
            -D $(cd $(dirname "$2") && pwd -P) |
            sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
        # then the diffs
        if cmp --quiet "$1" "$2"; then
            printf "==> no diffs found.\n"
        else
            diff -U 0 "$1" "$2" | awk -f formatUnifiedDiffOutput.awk
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_SKIP_EPISODES $SKIP_EPISODES)
$(checkdiffs $PUBLISHED_TCONST_LIST $TCONST_LIST)
$(checkdiffs $PUBLISHED_TCONST_ALL $TCONST_ALL)
$(checkdiffs $PUBLISHED_EPISODES_LIST $EPISODES_LIST)
$(checkdiffs $PUBLISHED_KNOWNFOR_LIST $KNOWNFOR_LIST)
$(checkdiffs $PUBLISHED_NCONST_LIST $NCONST_LIST)
$(checkdiffs $PUBLISHED_UNIQUE_TITLES $UNIQUE_TITLES)
$(checkdiffs $PUBLISHED_UNIQUE_PERSONS $UNIQUE_PERSONS)
$(checkdiffs $PUBLISHED_RAW_PERSONS $RAW_PERSONS)
$(checkdiffs $PUBLISHED_RAW_SHOWS $RAW_SHOWS)
$(checkdiffs $PUBLISHED_SHOWS $SHOWS)
$(checkdiffs $PUBLISHED_PERSONS $PERSONS)
$(checkdiffs $PUBLISHED_CREDITS_SHOW $CREDITS_SHOW)
$(checkdiffs $PUBLISHED_CREDITS_PERSON $CREDITS_PERSON)
$(checkdiffs $PUBLISHED_ASSOCIATED_TITLES $ASSOCIATED_TITLES)

### Any funny stuff with file lengths?

$(wc $ALL_WORKING $ALL_TXT $ALL_CSV $ALL_SPREADSHEETS)

EOF

exit
