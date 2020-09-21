#!/usr/bin/env bash
#
# Generate show and cast spreadsheets from:
#   1) a .tconst file containing a list of IMDb tconst identifiers
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
#    2) a .xlate file with pairs of non-English titles and their English equivalent for translation
#
#       For example:
#           Den fördömde	Sebastian Bergman
#           Der Bestatter	The Undertaker
#

# trap ctrl-c and call cleanup
trap cleanup INT
#
function cleanup() {
    printf "\n"
    exit 130
}

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Make sure we can execute rg.
if [ ! -x "$(which rg 2>/dev/null)" ]; then
    printf "[Error] Can't run rg. Install rg and rerun this script.\n"
    printf "        zgrep could be used, but is 15x slower in my tests.\n"
    printf "        See https://crates.io/crates/ripgrep for details.\n"
    exit 1
fi

# Make sure we have downloaded the IMDb files
if [ -e "name.basics.tsv.gz" ] && [ -e "title.basics.tsv.gz" ] && [ -e "title.principals.tsv.gz" ]; then
    printf "==> Using existing IMDb .gz files.\n"
else
    printf "==> Downloading new IMDb .gz files.\n"
    # Make sure we can execute curl.
    if [ ! -x "$(which curl 2>/dev/null)" ]; then
        printf "[Error] Can't run curl. Install curl and rerun this script.\n"
        printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
        exit 1
    fi
    for file in name.basics.tsv.gz title.basics.tsv.gz title.principals.tsv.gz; do
        if [ ! -e "$file" ]; then
            source="https://datasets.imdbws.com/$file"
            printf "Downloading $source\n"
            curl -s -O $source
        fi
    done
fi
printf "\n"

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

# Pick translation files to use
XLATE_FILES="*.xlate"

# Create some timestamps
DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# Required subdirectories
COLUMNS="IMDb-columns"
BASELINE="IMDb-baseline"
mkdir -p $COLUMNS $BASELINE

# Error and debugging info (per run)
POSSIBLE_DIFFS="IMDb_diffs$LONGDATE.txt"
ERRORS="IMDb_anomalies$LONGDATE.txt"

# Final output spreadsheets
CREDITS_SHOW="IMDb_Credits-Show$DATE_ID.csv"
CREDITS_PERSON="IMDb_Credits-Person$DATE_ID.csv"
SHOWS="IMDb_Shows$DATE_ID.csv"

# Intermediate working files
TCONST_LIST="$COLUMNS/tconst$DATE_ID.txt"
TITLE_LIST="$COLUMNS/titles$DATE_ID.txt"
NCONST_LIST="$COLUMNS/nconst$DATE_ID.txt"
RAW_SHOWS="$COLUMNS/raw_shows$DATE_ID.csv"
RAW_CREDITS="$COLUMNS/raw_credits$DATE_ID.csv"
UNSORTED_CREDITS="$COLUMNS/unsorted_credits$DATE_ID.csv"
#
CONST_PL="$COLUMNS/const-pl$DATE_ID.txt"
XLATE_PL="$COLUMNS/xlate-pl$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_CREDITS_SHOW="$BASELINE/credits-show.csv"
PUBLISHED_CREDITS_PERSON="$BASELINE/credits-person.csv"
PUBLISHED_SHOWS="$BASELINE/shows.csv"
#
PUBLISHED_TCONST_LIST="$BASELINE/tconst.txt"
PUBLISHED_TITLE_LIST="$BASELINE/titles.txt"
PUBLISHED_NCONST_LIST="$BASELINE/nconst.txt"
PUBLISHED_RAW_SHOWS="$BASELINE/raw_shows.csv"
PUBLISHED_RAW_CREDITS="$BASELINE/raw_credits.csv"

# Filename groups used for cleanup
ALL_WORKING="$TCONST_LIST $TITLE_LIST $NCONST_LIST $CONST_PL $XLATE_PL"
ALL_CSV="$RAW_CREDITS $RAW_SHOWS"
ALL_SPREADSHEETS="$SHOWS $CREDITS_SHOW $CREDITS_PERSON $UNSORTED_CREDITS"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_CSV $ALL_SPREADSHEETS

# Save a single tconst input list
rg -INz "^tt" $TCONST_FILES | sort -u >$TCONST_LIST

# Create a perl "substitute" script to translate any known non-English titles to their English equivalent
# Regex delimiter needs to avoid any characters present in the input, use {} for readability
perl -p -e 's+^+s{\\b+; s+\t+\\b}{+; s+$+};+' $XLATE_FILES >$XLATE_PL

# Generate a csv of titles from the tconst list, remove the "adult" field,
# translate any known non-English titles to their English equivalent,
# and manually translate the UTF-8 last character cases that don't work with a trailing word boundary
rg -wNz -f $TCONST_LIST title.basics.tsv.gz | cut -f 1-4,6-9 | perl -p -f $XLATE_PL |
    perl -p -e 's+\bMeurtres à...+Murder In...+; s+\bLa scomparsa di Patò+The Vanishing of Patò+' |
    sort -fu --key=3 | tee $RAW_SHOWS | cut -f 3 | sort -fu >$TITLE_LIST
#
# Let us know what shows we're processing - format for readability, separate with ";"
num_titles=$(sed -n '$=' $TITLE_LIST)
printf "\n==> Processing $num_titles shows found in $TCONST_FILES:\n"
perl -p -e 's+$+;+' $TITLE_LIST | fmt -w 80 | perl -p -e 's+^+\t+' | sed '$ s+.$++'

# Use tconst list to lookup principal credits and create an nconst list
# Generate a csv of principal nconsts and names of characters they portrayed from title matches
# Add the nconst list of all known cast members from shows we know about
rg -wNz -f $TCONST_LIST title.principals.tsv.gz | sort --key=1,1 --key=2,2n | tee $RAW_CREDITS |
    rg -wN -e actor -e actress -e writer -e director | cut -f 3 | sort -u >$NCONST_LIST

# Create a perl script to convert a tconst to a title, and an nconst to a name
cut -f 1,3 $RAW_SHOWS | perl -F"\t" -lane \
    'print "s{\\b".@F[0]."\\b}{=HYPERLINK(\"https://www.imdb.com/title/".@F[0]."\";\"".@F[1]."\")}g;";' \
    >$CONST_PL
rg -wNz -f $NCONST_LIST name.basics.tsv.gz | cut -f 1-2 | sort -fu --key=2 | perl -F"\t" -lane \
    'print "s{\\b".@F[0]."\\b}{=HYPERLINK(\"https://www.imdb.com/name/".@F[0]."\";\"".@F[1]."\")}g;";' \
    >>$CONST_PL

# Get rid of ugly \N fields, unneeded characters, and commas not followed by spaces
perl -pi -e 's+\\N++g; tr+"[]++d; s+,+, +g; s+,  +, +g;' $ALL_CSV

# Create the SHOWS spreadsheet by rearranging RAW_SHOWS fields
printf "Primary Title\tShow Type\tOriginal Title\tStart\tEnd\tMinutes\tGenres\n" >$SHOWS
cut -f 1,2,4-8 $RAW_SHOWS >>$SHOWS

# Create the UNSORTED_CREDITS spreadsheet by rearranging RAW_CREDITS fields
perl -F"\t" -lane 'printf "%s\t%s\t%02d\t%s\t%s\n", @F[2,0,1,3,5]' $RAW_CREDITS >$UNSORTED_CREDITS

# Translate tconst and nconst into titles and names
perl -pi -f $CONST_PL $SHOWS
perl -pi -f $CONST_PL $UNSORTED_CREDITS

# Create the sorted CREDITS spreadsheets
printf "Person\tShow Title\tRank\tJob\tCharacter Name\n" | tee $CREDITS_SHOW >$CREDITS_PERSON
rg -v -e "^nm" -e "\tproducer\t" $UNSORTED_CREDITS |
    sort -f --field-separator=\" --key=4,4 --key=8 >>$CREDITS_PERSON
rg -v -e "^nm" -e "\tproducer\t" $UNSORTED_CREDITS |
    sort -f --field-separator=\" --key=8 --key=4,4 >>$CREDITS_SHOW

# Shortcut for printing file info (before adding totals)
function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    filesize=$(ls -loh $1 | cut -c 22-26)
    filedate=$(ls -loh $1 | cut -c 28-39)
    numlines=$(($(sed -n '$=' $1) - $2))
    printf "%-45s%6s%15s%9d lines\n" "$1" "$filesize" "$filedate" "$numlines"
}

# Output some stats, adjust by 1 if header line is included.
printf "\n==> Stats from processing raw tconst data:\n"
printAdjustedFileInfo $TITLE_LIST 0
printAdjustedFileInfo $RAW_SHOWS 0
printAdjustedFileInfo $SHOWS 1
printAdjustedFileInfo $NCONST_LIST 0
printAdjustedFileInfo $CREDITS_SHOW 1
printAdjustedFileInfo $CREDITS_PERSON 1
printAdjustedFileInfo $RAW_CREDITS 0

# Shortcut for checking differences between two files.
# checkdiffs basefile newfile
function checkdiffs() {
    printf "\n"
    if [ ! -e "$1" ]; then
        # If the basefile file doesn't yet exist, assume no differences
        # and copy the newfile to the basefile so it can serve
        # as a base for diffs in the future.
        printf "==> $1 does not exist. Creating it, assuming no diffs.\n"
        cp -p "$2" "$1"
    else
        printf "==> what changed between $1 and $2:\n"
        # first the stats
        diff -c "$1" "$2" | diffstat -sq \
            -D $(cd $(dirname "$2") && pwd -P) |
            sed -e "s+ 1 file changed,+==>+" -e "s+([+-=\!])++g"
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
            printf "==> no diffs found.\n"
        fi
    fi
}

# Preserve any possible errors for debugging
cat >>$POSSIBLE_DIFFS <<EOF
==> ${0##*/} completed: $(date)

### Check the diffs to see if any changes are meaningful
$(checkdiffs $PUBLISHED_TITLE_LIST $TITLE_LIST)
$(checkdiffs $PUBLISHED_TCONST_LIST $TCONST_LIST)
$(checkdiffs $PUBLISHED_NCONST_LIST $NCONST_LIST)
$(checkdiffs $PUBLISHED_RAW_SHOWS $RAW_SHOWS)
$(checkdiffs $PUBLISHED_RAW_CREDITS $RAW_CREDITS)
$(checkdiffs $PUBLISHED_SHOWS $SHOWS)
$(checkdiffs $PUBLISHED_CREDITS_SHOW $CREDITS_SHOW)
$(checkdiffs $PUBLISHED_CREDITS_PERSON $CREDITS_PERSON)

### Any funny stuff with file lengths?

$(wc $ALL_WORKING $ALL_CSV $ALL_SPREADSHEETS)

EOF

exit
