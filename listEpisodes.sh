#!/usr/bin/env bash
# Print episode descriptions from the latest spreadsheets using a case insensitive search
# If you get too many results, copy/paste a portion of the title string from one of the results
#
# EXAMPLES:
#    ./listEpisodes.sh wallander               176 lines
#    ./listEpisodes.sh Wallander,              134 lines
#    ./listEpisodes.sh Wallander, S03           39 lines
#    ./listEpisodes.sh Wallander, S03E03         5 lines
#
# Some regular expressions require quotes
#    ./listEpisodes.sh Wallander, S0..03         9 lines
#    ./listEpisodes.sh "Wallander, S0[2-3]"     51 lines
#
# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

ACORN=$(find . -d 1 -name "Acorn_TV_ShowsEpisodes*csv" | sort | tail -1 | cut -c 3-)
BBOX=$(find . -d 1 -name "BBox_TV_ShowsEpisodes*csv" | sort | tail -1 | cut -c 3-)
MHZ=$(find . -depth 1 -name "MHz_TV_ShowsEpisodes*csv" | sort | tail -1 | cut -c 3-)

if [ $ACORN ] && [ $(cut -f 1 $ACORN | grep -i -c "$*") != 0 ]; then
    echo "==> From $ACORN"
    linesFound="yes"
    grep -i "$*" $ACORN | cut -f 1,4,5 | awk -f printList.awk
fi

if [ $BBOX ] && [ $(cut -f 2 $BBOX | grep -i -c "$*") != 0 ]; then
    if [ "$linesFound" = "yes" ]; then
        printf "\n"
    fi
    echo "==> From $BBOX"
    linesFound="yes"
    grep -i "$*" $BBOX | cut -f 2,5,9 | awk -f printList.awk
fi

if [ $MHZ ] && [ $(cut -f 1 $MHZ | grep -i -c "$*") != 0 ]; then
    if [ "$linesFound" = "yes" ]; then
        printf "\n"
    fi
    echo "==> From $MHZ"
    grep -i "$*" $MHZ | cut -f 1,4,9 | awk -f printList.awk
fi
