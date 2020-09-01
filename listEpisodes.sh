#!/usr/bin/env bash
# Case insensitive search latest spreadsheets Print episode titles, durations, and descriptions
# -f format     -- Format the description using fmt
# -w width      -- Change the wrap column from the default 80
#
# If you get too many results, copy/paste a portion of the title string from one of the results
#
# EXAMPLES:
#    ./listEpisodes.sh wallander               183 lines
#    ./listEpisodes.sh Wallander,              135 lines
#    ./listEpisodes.sh Wallander, S03           39 lines
#    ./listEpisodes.sh Wallander, S03E03         5 lines
#
# Some regular expressions require quotes
#    ./listEpisodes.sh Wallander, S0..03         9 lines
#    ./listEpisodes.sh "Wallander, S0[2-3]"     51 lines

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Default width to 80
WIDTH="80"

# Allow user to override width
while getopts ":w:f" opt; do
    case $opt in
    w)
        WIDTH="$OPTARG"
        ;;
    f)
        FMT="yes"
        ;;
    \?)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    :)
        printf "Option -$OPTARG requires a 'width' argument such as '-w 80'." >&2
        exit 1
        ;;
    esac
done
shift $((OPTIND - 1))

# -f followed by -w doesn't work, so wait until all switches are processed
if [ $FMT ]; then cmd="fmt -w $WIDTH"; else cmd="cat"; fi

ACORN=$(find . -d 1 -name "Acorn_TV_ShowsEpisodes*csv" | sort | tail -1 | cut -c 3-)
BBOX=$(find . -d 1 -name "BBox_TV_ShowsEpisodes*csv" | sort | tail -1 | cut -c 3-)
MHZ=$(find . -depth 1 -name "MHz_TV_ShowsEpisodes*csv" | sort | tail -1 | cut -c 3-)

if [ $ACORN ] && [ $(cut -f 1,5 $ACORN | grep -i -c "$*") != 0 ]; then
    printf "==> From $ACORN\n"
    linesFound="yes"
    grep -i "$*" $ACORN | cut -f 1,4,5 | awk -v FMT=$FMT -v WIDTH=$WIDTH \
        -f printList.awk | $cmd
fi

if [ $BBOX ] && [ $(cut -f 2,9 $BBOX | grep -i -c "$*") != 0 ]; then
    if [ "$linesFound" = "yes" ]; then printf "\n"; fi
    printf "==> From $BBOX\n"
    linesFound="yes"
    grep -i "$*" $BBOX | cut -f 2,5,9 | awk -v FMT=$FMT -v WIDTH=$WIDTH \
        -f printList.awk | $cmd
fi

if [ $MHZ ] && [ $(cut -f 1,9 $MHZ | grep -i -c "$*") != 0 ]; then
    if [ "$linesFound" = "yes" ]; then printf "\n"; fi
    printf "==> From $MHZ\n"
    grep -i "$*" $MHZ | cut -f 1,4,9 | awk -v FMT=$FMT -v WIDTH=$WIDTH \
                -f printList.awk | $cmd
fi