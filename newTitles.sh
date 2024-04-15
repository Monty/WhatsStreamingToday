#!/usr/bin/env bash
#
# prettydiff the most recent uniqTitles files from MHz, Acorn, OPB, and Britbox

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

source waitUntil.function

ACORN_TITLES=$(find Acorn_uniqTitles-*txt | tail -1)
ACORN_TITLES_OLD=$(find Acorn_uniqTitles-*txt | tail -2 | head -1)
#
BBOX_TITLES=$(find BBox_uniqTitles-*txt | tail -1)
BBOX_TITLES_OLD=$(find BBox_uniqTitles-*txt | tail -2 | head -1)
#
MHZ_TITLES=$(find MHz_uniqTitles-*txt | tail -1)
MHZ_TITLES_OLD=$(find MHz_uniqTitles-*txt | tail -2 | head -1)
#
OPB_TITLES=$(find OPB_uniqTitles-*txt | tail -1)
OPB_TITLES_OLD=$(find OPB_uniqTitles-*txt | tail -2 | head -1)

# First as a table with both new and removed
printf "==> New titles in $MHZ_TITLES\n"
prettydiff "$MHZ_TITLES_OLD" "$MHZ_TITLES"
waitUntil -k "==> New titles in $ACORN_TITLES"

prettydiff "$ACORN_TITLES_OLD" "$ACORN_TITLES"
waitUntil -k "==> New titles in $OPB_TITLES"

prettydiff "$OPB_TITLES_OLD" "$OPB_TITLES"
waitUntil -k "==> New titles in $BBOX_TITLES"

prettydiff "$BBOX_TITLES_OLD" "$BBOX_TITLES"
waitUntil -k "==> All new titles as plain text"

# Now just as plain text
printf "\n==> New titles in $MHZ_TITLES\n"
zet diff "$MHZ_TITLES" "$MHZ_TITLES_OLD"

printf "\n==> New titles in $ACORN_TITLES\n"
zet diff "$ACORN_TITLES" "$ACORN_TITLES_OLD"

printf "\n==> New titles in $OPB_TITLES\n"
zet diff "$OPB_TITLES" "$OPB_TITLES_OLD"

printf "\n==> New titles in $BBOX_TITLES\n"
zet diff "$BBOX_TITLES" "$BBOX_TITLES_OLD"
