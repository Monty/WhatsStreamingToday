#!/usr/bin/env bash
#
# diff the most recent TV_ShowsEpisodes files from MHz, Acorn, OPB, and Britbox
# and print the new episodes
#
# Assume episodes have a season mumber in field 1, i.e. ', S[0-9][0-9]'

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

# shellcheck disable=SC1091 # waitUntil.function is a local file
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

printf "==> Show new episodes in $MHZ_EPISODES"
if waitUntil -Y "?"; then
    zet diff \
        <(cut -f 1 "$MHZ_EPISODES" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$MHZ_EPISODES_OLD" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) | rg -v ', $'
fi

printf "\n==> Show new episodes in $ACORN_EPISODES"
if waitUntil -Y "?"; then
    zet diff \
        <(cut -f 1 "$ACORN_EPISODES" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$ACORN_EPISODES_OLD" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) | rg -v 'Coming Soon'
fi

printf "\n==> Show new episodes in $OPB_EPISODES"
if waitUntil -Y "?"; then
    zet diff \
        <(cut -f 1 "$OPB_EPISODES" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$OPB_EPISODES_OLD" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk)
fi

printf "\n==> Show new episodes in $BBOX_EPISODES"
if waitUntil -Y "?"; then
    zet diff \
        <(cut -f 1 "$BBOX_EPISODES" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$BBOX_EPISODES_OLD" | rg ', S[0-9][0-9]' |
            awk -f printTitles.awk) |
        rg -v 'Coming Soon|Coronation Street|Doctors|EastEnders|Emmerdale' |
        rg -v 'Good Morning Britain|Landward|Question Time|RHS Chelsea Flower Show' |
        rg -v 'The Beechgrove Garden' | rg -v 'Escape to the Country' |
        rg -v "Gardeners' World"
fi
