#!/usr/bin/env bash
#
# Find common cast members between multiple shows
#
# NOTES:
#   Requires cast member files produced by makeIMDbFromFiles-noHype.sh and/or other make*.sh scripts.
#   Cast member data from IMDb and streaming service providers often has mistakes.
#   Titles may differ between services, e.g. Gåsmamman/gasmamman, Jägarna/the-hunters
#
#   To help refine searches, the output is rather wordy.
#   The final section (Duplicated names) is the section of interest.
#
#   It may help to start with an actor, e.g.
#       ./commCast.sh 'Alexandra Rapaport'
#   Then move to more complex queries that expose other common cast members
#       ./commCast.sh spring-tide the-sandhamn-murders the-team
#   Experiment to find the most useful results.
#
# EXAMPLES:
#     ./commCast.sh murder-in blood-of-the-vine
#     ./commCast.sh Brandvägg Jägarna "En man som heter Ove" "En pilgrims död"

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Need some tempfiles
TMPFILE=$(mktemp)
SRCHFILE=$(mktemp)

# trap ctrl-c and call cleanup
trap cleanup INT
#
function cleanup() {
    rm -rf $TMPFILE $SRCHFILE
    printf "\n"
    exit 130
}
# Get latest files to search
BBOX="$(ls -1t BBox_TV_Credits*csv 2>/dev/null | head -1)"
MHZ="$(ls -1t MHz_TV_Credits*csv 2>/dev/null | head -1)"
IMDb="$(ls -1t IMDb_Credits-Person-noHype*csv 2>/dev/null | head -1)"
# Get latest files to use for translating show names
XLATE="$(ls -1t IMDb-columns/xlate-pl-noHype*.txt 2>/dev/null | head -1)"

printf "==> Files processed:\n"
#
if [ $BBOX ]; then
    printf "BBOX:\t$BBOX\n"
    foundFiles="yes"
else
    printf "BBOX:\tNo files match BBox_TV_Credits*csv\n"
fi
#
if [ $MHZ ]; then
    printf "MHZ:\t$MHZ\n"
    foundFiles="yes"
else
    printf "MHZ:\tNo files match MHz_TV_Credits*csv\n"
fi
#
if [ $IMDb ]; then
    printf "IMDb:\t$IMDb\n"
    foundFiles="yes"
else
    printf "IMDb:\tNo files match IMDb_Credits-Person-noHype*csv\n"
fi
#
if [ "$foundFiles" != "yes" ]; then
    printf "==> [Error] No files available to process.\n"
    exit 1
fi
#
if [ $XLATE ]; then
    printf "XLATE:\t$XLATE\n"
else
    printf "XLATE:\tNo files match IMDb-columns/xlate-pl*.txt\n"
    printf "\tNo translation will be done.\n"
fi

printf "\n==> Searching for:\n"
for a in "$@"; do
    printf "$a\n" >>$SRCHFILE
done
cat $SRCHFILE

printf "\n==> All names (Name|Job|Show|Role):\n"
#
if [ $BBOX ]; then
    if [ $(rg -wS -c -f $SRCHFILE $BBOX) ]; then
        rg -wSIN --color always -f $SRCHFILE $BBOX |
            awk -F "\t" '{printf ("%s\t%s\t%s\t%s\n", $1,$2,$4,$5)}' >>$TMPFILE
    fi
fi
#
if [ $MHZ ]; then
    if [ $(rg -wS -c -f $SRCHFILE $MHZ) ]; then
        rg -wSIN --color always -f $SRCHFILE $MHZ |
            awk -F "\t" '{printf ("%s\t%s\t%s\t%s\n", $1,$2,$4,$5)}' >>$TMPFILE
    fi
fi
#
if [ $IMDb ]; then
    if [ $(rg -wS -c -f $SRCHFILE $IMDb) ]; then
        if [ $XLATE ]; then
            perl -p -f $XLATE $IMDb | rg -wSIN --color always -f $SRCHFILE |
                awk -F "\t" '{printf ("%s\t%s\t%s\t%s\n", $1,$5,$3,$6)}' >>$TMPFILE
        else
            rg -wSIN --color always -f $SRCHFILE $IMDb |
                awk -F "\t" '{printf ("%s\t%s\t%s\t%s\n", $1,$5,$3,$6)}' >>$TMPFILE
        fi
    fi
fi

# Print all search results
TAB=$(printf "\t")
sort -f --field-separator="$TAB" --key=1,1 --key=3,3 -fu $TMPFILE |
    awk -F "\t" '{printf ("%-20s\t%-8s\t%-35s\t%-20s\n",$1,$2,$3,$4)}'

printf "\n==> Duplicated names (Name|Job|Show|Role):\n"
# Spacing is sometimes erratic due to UTF-8 characters
sort -f --field-separator="$TAB" --key=1,1 --key=3,3 -fu $TMPFILE |
    awk -F "\t" 'BEGIN {p="%-20s\t%-8s\t%-35s\t%-20s\n"} {if($1==f[1]&&$3!=f[3])
        {printf(p,f[1],f[2],f[3],f[4]); printf(p,$1,$2,$3,$4)} split($0,f)}' | sort -fu

rm -rf $TMPFILE $SRCHFILE
