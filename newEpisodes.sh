#!/usr/bin/env bash
#
# diff the most recent TV_ShowsEpisodes files from MHz, Acorn, OPB, and Britbox
# and print new, removed, or changed episodes

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

source waitUntil.function

ACORN_EPISODES=$(find Acorn_TV_ShowsEpisodes-*csv | tail -1)
ACORN_EPISODES_OLD=$(find Acorn_TV_ShowsEpisodes-*csv | tail -2 | head -1)
#
BBOX_EPISODES=$(find BBox_TV_ShowsEpisodes-*csv | tail -1)
BBOX_EPISODES_OLD=$(find BBox_TV_ShowsEpisodes-*csv | tail -2 | head -1)
#
MHZ_EPISODES=$(find MHz_TV_ShowsEpisodes-*csv | tail -1)
MHZ_EPISODES_OLD=$(find MHz_TV_ShowsEpisodes-*csv | tail -2 | head -1)
#
OPB_EPISODES=$(find OPB_TV_ShowsEpisodes-*csv | tail -1)
OPB_EPISODES_OLD=$(find OPB_TV_ShowsEpisodes-*csv | tail -2 | head -1)

printf "==> $TYPE episodes in $MHZ_EPISODES\n"
zet diff \
    <(awk -f printTitles.awk "$MHZ_EPISODES") \
    <(awk -f printTitles.awk "$MHZ_EPISODES_OLD")
waitUntil -kY "==> $TYPE episodes in $ACORN_EPISODES"

zet diff \
    <(awk -f printTitles.awk "$ACORN_EPISODES") \
    <(awk -f printTitles.awk "$ACORN_EPISODES_OLD")
waitUntil -kY "==> $TYPE episodes in $OPB_EPISODES"

zet diff \
    <(awk -f printTitles.awk "$OPB_EPISODES") \
    <(awk -f printTitles.awk "$OPB_EPISODES_OLD")
waitUntil -kY "==> $TYPE episodes in $BBOX_EPISODES"

zet diff \
    <(awk -f printTitles.awk "$BBOX_EPISODES") \
    <(awk -f printTitles.awk "$BBOX_EPISODES_OLD")
