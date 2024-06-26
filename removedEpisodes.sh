#!/usr/bin/env bash
#
# diff the most recent TV_ShowsEpisodes files from MHz, Acorn, OPB, and Britbox
# and print the removed episodes
#
# Assume episodes have a season mumber in field 1, i.e. ', S[0-9][0-9]'

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

# Default to finding removed episodes
TYPE="Removed"

waitUntil -k "==> $TYPE episodes in $MHZ_EPISODES"
zet diff \
    <(cut -f 1 "$MHZ_EPISODES_OLD" | rg ', S[0-9][0-9]' | awk -f printTitles.awk) \
    <(cut -f 1 "$MHZ_EPISODES" | rg ', S[0-9][0-9]' | awk -f printTitles.awk)

waitUntil -k "==> $TYPE episodes in $ACORN_EPISODES"
zet diff \
    <(cut -f 1 "$ACORN_EPISODES_OLD" | rg ', S[0-9][0-9]' | awk -f printTitles.awk) \
    <(cut -f 1 "$ACORN_EPISODES" | rg ', S[0-9][0-9]' | awk -f printTitles.awk)

waitUntil -k "==> $TYPE episodes in $OPB_EPISODES"
zet diff \
    <(cut -f 1 "$OPB_EPISODES_OLD" | rg ', S[0-9][0-9]' | awk -f printTitles.awk) \
    <(cut -f 1 "$OPB_EPISODES" | rg ', S[0-9][0-9]' | awk -f printTitles.awk)

waitUntil -k "==> $TYPE episodes in $BBOX_EPISODES"
zet diff \
    <(cut -f 1 "$BBOX_EPISODES_OLD" | rg ', S[0-9][0-9]' | awk -f printTitles.awk) \
    <(cut -f 1 "$BBOX_EPISODES" | rg ', S[0-9][0-9]' | awk -f printTitles.awk)
