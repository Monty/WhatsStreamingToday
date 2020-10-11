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

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Default translation files to all .xlate files, but allow user to override
XLATE_FILES="*.xlate"
while getopts ":t:h" opt; do
    case $opt in
    h)
        printf "Create spreadsheets of shows, actors, and the characters they portray\n"
        printf "from downloaded IMDb .gz fies. See https://www.imdb.com/interfaces/\n\n"
        printf "USAGE:\n"
        printf "    ./makeIMDbFromFiles.sh [-t translation file] [tconst file ...]\n"
        exit
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
POSSIBLE_DIFFS="IMDb_diffs$LONGDATE.txt"
ERRORS="IMDb_anomalies$LONGDATE.txt"

# Final output spreadsheets
CREDITS_SHOW="IMDb_Credits-Show$DATE_ID.csv"
CREDITS_PERSON="IMDb_Credits-Person$DATE_ID.csv"
PERSONS="IMDb_Persons-Titles$DATE_ID.csv"
SHOWS="IMDb_Shows$DATE_ID.csv"
ASSOCIATED_TITLES="IMDb_associatedTitles$DATE_ID.csv"

# Final output lists
UNIQUE_PERSONS="IMDb_uniqPersons$DATE_ID.txt"
UNIQUE_TITLES="IMDb_uniqTitles$DATE_ID.txt"

# Intermediate working files
TCONST_ALL="$COLS/tconst_all$DATE_ID.txt"
TCONST_LIST="$COLS/tconst$DATE_ID.txt"
KNOWNFOR_LIST="$COLS/tconst_known$DATE_ID.txt"
NCONST_LIST="$COLS/nconst$DATE_ID.txt"
RAW_SHOWS="$COLS/raw_shows$DATE_ID.csv"
RAW_PERSONS="$COLS/raw_persons$DATE_ID.csv"
UNSORTED_CREDITS="$COLS/unsorted_credits$DATE_ID.csv"
#
TCONST_PRIM_PL="$COLS/tconst-prim-pl$DATE_ID.txt"
TCONST_ORIG_PL="$COLS/tconst-orig-pl$DATE_ID.txt"
TCONST_KNOWN_PL="$COLS/tconst-known-pl$DATE_ID.txt"
NCONST_PL="$COLS/nconst-pl$DATE_ID.txt"
XLATE_PL="$COLS/xlate-pl$DATE_ID.txt"

# Saved files used for comparison with current files
PUBLISHED_CREDITS_SHOW="$BASELINE/credits-show.csv"
PUBLISHED_CREDITS_PERSON="$BASELINE/credits-person.csv"
PUBLISHED_PERSONS="$BASELINE/persons-titles.csv"
PUBLISHED_SHOWS="$BASELINE/shows.csv"
PUBLISHED_ASSOCIATED_TITLES="$BASELINE/associatedTitles.csv"
#
PUBLISHED_UNIQUE_PERSONS="$BASELINE/uniqPersons.txt"
PUBLISHED_UNIQUE_TITLES="$BASELINE/uniqTitles.txt"
#
PUBLISHED_TCONST_ALL="$BASELINE/tconst_all.txt"
PUBLISHED_TCONST_LIST="$BASELINE/tconst.txt"
PUBLISHED_KNOWNFOR_LIST="$BASELINE/tconst_known.txt"
PUBLISHED_NCONST_LIST="$BASELINE/nconst.txt"
PUBLISHED_RAW_SHOWS="$BASELINE/raw_shows.csv"
PUBLISHED_RAW_PERSONS="$BASELINE/raw_persons.csv"

# Filename groups used for cleanup
ALL_WORKING="$TCONST_LIST $NCONST_LIST $TCONST_ALL $KNOWNFOR_LIST "
ALL_WORKING+="$XLATE_PL $TCONST_PRIM_PL $TCONST_ORIG_PL $NCONST_PL $TCONST_KNOWN_PL"
ALL_TXT="$UNIQUE_TITLES $UNIQUE_PERSONS"
ALL_CSV="$RAW_SHOWS $RAW_PERSONS $UNSORTED_CREDITS"
ALL_SPREADSHEETS="$SHOWS $PERSONS $CREDITS_SHOW $CREDITS_PERSON $ASSOCIATED_TITLES"

# Cleanup any possible leftover files
rm -f $ALL_WORKING $ALL_TXT $ALL_CSV $ALL_SPREADSHEETS

# Create a master tconst_all
rg -IN "^tt" *.tconst | cut -f 1 | sort -u >$TCONST_ALL
# Coalesce a single tconst input list
rg -IN "^tt" $TCONST_FILES | cut -f 1 | sort -u >$TCONST_LIST

# Create a perl "substitute" script to translate any known non-English titles to their English equivalent
# Regex delimiter needs to avoid any characters present in the input, use {} for readability
rg -INv -e "^#" -e "^$" $XLATE_FILES | cut -f 1,2 | sort -fu |
    perl -p -e 's+\t+\\t}{\\t+; s+^+s{\\t+; s+$+\\t};+' >$XLATE_PL

# Generate a csv of titles from the tconst list, remove the "adult" field,
# translate any known non-English titles to their English equivalent,
# Sort by Primary Title (3), Start (5), Original Title (4)
TAB=$(printf "\t")
rg -wNz -f $TCONST_LIST title.basics.tsv.gz | cut -f 1-4,6-9 | perl -p -f $XLATE_PL |
    sort -f --field-separator="$TAB" --key=3,3 --key=5,5 --key=4,4 | tee $RAW_SHOWS | cut -f 3 |
    sort -fu >$UNIQUE_TITLES
#
# Let us know what shows we're processing - format for readability, separate with ";"
num_titles=$(sed -n '$=' $UNIQUE_TITLES)
printf "\n==> Processing $num_titles shows found in $TCONST_FILES:\n"
perl -p -e 's+$+;+' $UNIQUE_TITLES | fmt -w 80 | perl -p -e 's+^+\t+' | sed '$ s+.$++'

# Use the tconst list to lookup principal titles and generate a tconst/nconst credits csv
# Fix bogus nconst nm0745728, it should be m0745694. Rearrange fields
rg -wNz -f $TCONST_LIST title.principals.tsv.gz | rg -wN -e actor -e actress -e writer -e director |
    sort --key=1,1 --key=2,2n | perl -p -e 's+nm0745728+nm0745694+' |
    perl -F"\t" -lane 'printf "%s\t%s\t%s\t%02d\t%s\t%s\n", @F[2,0,0,1,3,5]' >$UNSORTED_CREDITS

# Generate an nconst list for later processing
cut -f 1 $UNSORTED_CREDITS | sort -u >$NCONST_LIST

# Create a perl script to convert the 1st tconst to a primary title link
cut -f 1,3 $RAW_SHOWS | perl -F"\t" -lane \
    'print "s{\\b" . @F[0] . "\\b}{=HYPERLINK(\"https://www.imdb.com/title/" . @F[0] . "\";\""
    . @F[1] . "\")};";' >$TCONST_PRIM_PL
# Create a perl script to convert the 2nd tconst to an original title link
cut -f 1,4 $RAW_SHOWS | perl -F"\t" -lane \
    'print "s{\\t" . @F[0] . "\\t}{\\t=HYPERLINK(\"https://www.imdb.com/title/" . @F[0] . "\";\""
    .@F[1] . "\")\\t};";' >$TCONST_ORIG_PL
# Create a perl script to convert an nconst to a name link
rg -wNz -f $NCONST_LIST name.basics.tsv.gz | cut -f 1-2,6 | sort -fu --key=2 | tee $RAW_PERSONS |
    perl -F"\t" -lane 'print "s{\\b" . @F[0] . "\\b}{=HYPERLINK(\"https://www.imdb.com/name/"
    .@F[0] . "\";\"" . @F[1] . "\")};";' >$NCONST_PL

# Get rid of ugly \N fields, unneeded characters, and make sure commas are followed by spaces
perl -pi -e 's+\\N++g; tr+"[]++d; s+,+, +g; s+,  +, +g;' $ALL_CSV

# Create the PERSONS spreadsheet
printf "Person\tKnown For Titles 1\tKnown For Titles 2\tKnown For Titles 3\tKnown For Titles 4\n" >$PERSONS
cut -f 1,3 $RAW_PERSONS | perl -p -e 's+, +\t+g' >>$PERSONS

# Create a tconst list of the knownForTitles
cut -f 3 $RAW_PERSONS | rg "^tt" | perl -p -e 's+, +\n+g' | sort -u >$KNOWNFOR_LIST
# Create a perl script to convert a known tconst to a primary title link
rg -wNz -f $KNOWNFOR_LIST title.basics.tsv.gz | perl -p -f $XLATE_PL | cut -f 1,3 |
    perl -F"\t" -lane \
        'print "s{\\b" . @F[0] . "\\b}{=HYPERLINK(\"https://www.imdb.com/title/" . @F[0] . "\";\""
    . @F[1] . "\")};";' >$TCONST_KNOWN_PL

# Create a spreadsheet of associated titles gained from IMDb knownFor data
printf "tconst\tPrimary Title\tLink to Title\n" >$ASSOCIATED_TITLES
# s{\btt0024710\b}{=HYPERLINK("https://www.imdb.com/title/tt0024710";"La tête d'un homme")};
perl -p -e 's+^.*/tt+tt+; s+"+\t+g;' $TCONST_KNOWN_PL | cut -f 1,3 |
    perl -F"\t" -lane 'print @F[0] . "\t" . @F[1] . "\t=HYPERLINK(\"https://www.imdb.com/title/"
    . @F[0] . "\";\"" . @F[1] ."\")"' |
    sort -fu --field-separator="$TAB" --key=2,2 | rg -wv -f $TCONST_ALL >>$ASSOCIATED_TITLES

# Create the SHOWS spreadsheet by removing "Original Title" field from RAW_SHOWS
printf "Primary Title\tShow Type\tOriginal Title\tStart\tEnd\tMinutes\tGenres\n" >$SHOWS
cut -f 1,2,4-8 $RAW_SHOWS >>$SHOWS

# Translate tconst and nconst into titles and names
perl -pi -f $TCONST_PRIM_PL $SHOWS
perl -pi -f $TCONST_PRIM_PL $UNSORTED_CREDITS
perl -pi -f $TCONST_ORIG_PL $UNSORTED_CREDITS
perl -pi -f $NCONST_PL $UNSORTED_CREDITS
perl -pi -f $TCONST_KNOWN_PL $PERSONS
perl -pi -f $NCONST_PL $PERSONS

# Create UNIQUE_PERSONS
cut -f 2 $RAW_PERSONS | sort -fu >$UNIQUE_PERSONS

# Create the sorted CREDITS spreadsheets
printf "Person\tPrimary Title\tOriginal Title\tRank\tJob\tCharacter Name\n" |
    tee $CREDITS_SHOW >$CREDITS_PERSON
# Sort by Person (4), Primary Title (8), Rank (13)
sort -f --field-separator=\" --key=4,4 --key=8,8 --key=13,13 --key=12,12 \
    $UNSORTED_CREDITS >>$CREDITS_PERSON
# Sort by Primary Title (8), Original Title (12), Rank (13)
sort -f --field-separator=\" --key=8,8 --key=12,13 $UNSORTED_CREDITS >>$CREDITS_SHOW

# Shortcut for printing file info (before adding totals)
function printAdjustedFileInfo() {
    # Print filename, size, date, number of lines
    # Subtract lines to account for headers or trailers, 0 for no adjustment
    #   INVOCATION: printAdjustedFileInfo filename adjustment
    numlines=$(($(sed -n '$=' $1) - $2))
    ls -loh $1 |
        awk -v nl=$numlines '{ printf ("%-46s %s %s %s %9d lines\n", $8, $5, $6, $7, nl); }'
}

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
printAdjustedFileInfo $ASSOCIATED_TITLES 0
# printAdjustedFileInfo $KNOWNFOR_LIST 0

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
$(checkdiffs $PUBLISHED_TCONST_LIST $TCONST_LIST)
$(checkdiffs $PUBLISHED_TCONST_ALL $TCONST_ALL)
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
