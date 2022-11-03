#!/usr/bin/env bash
# Diff the most recent two anomalies files

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

ACORN_ANOMS=$(find Acorn_anomalies-*txt | tail -1)
ACORN_ANOMS_OLD=$(find Acorn_anomalies-*txt | tail -2 | head -1)
ACORN_DIFFS=$(find Acorn_diffs-*txt | tail -1)
#
BBOX_ANOMS=$(find BBox_anomalies-*txt | tail -1)
BBOX_ANOMS_OLD=$(find BBox_anomalies-*txt | tail -2 | head -1)
BBOX_DIFFS=$(find BBox_diffs-*txt | tail -1)
#
MHZ_ANOMS=$(find MHz_anomalies-*txt | tail -1)
MHZ_ANOMS_OLD=$(find MHz_anomalies-*txt | tail -2 | head -1)
MHZ_DIFFS=$(find MHz_diffs-*txt | tail -1)

function waitForKey() {
    read -r -n 1 -s -p "Hit any key to clear screen and continue, '^C' to quit. "
    clear
}

clear

./whatChanged "$ACORN_ANOMS" "$ACORN_ANOMS_OLD"
waitForKey

./whatChanged "$BBOX_ANOMS" "$BBOX_ANOMS_OLD"
waitForKey

./whatChanged "$MHZ_ANOMS" "$MHZ_ANOMS_OLD"
waitForKey

view "$ACORN_DIFFS" "$BBOX_DIFFS" "$MHZ_DIFFS"
