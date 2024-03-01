#!/usr/bin/env bash
# Diff the most recent two anomalies files and view the most recent diffs
# from Acorn, Britbox, MHz and OPB updates. Offer to save today's files.

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

source waitUntil.function

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
#
# Most recent is from addOPB-episodeDescriptions.sh
OPB_ANOMS=$(find OPB_anomalies-*txt | tail -1)
OPB_ANOMS_OLD=$(find OPB_anomalies-*txt | tail -2 | head -1)
OPB_DIFFS=$(find OPB_diffs-*txt | tail -1)
# Older output is from makeOPB.sh
ADDOPB_ANOMS=$(find addOPB_anomalies-*txt | tail -1)
ADDOPB_ANOMS_OLD=$(find addOPB_anomalies-*txt | tail -2 | head -1)
ADDOPB_DIFFS=$(find addOPB_diffs-*txt | tail -1)

clear

tail -8 timeAllScripts.stdout.txt timeAllScripts.stderr.txt

waitUntil -k
clear

./whatChanged "$ACORN_ANOMS_OLD" "$ACORN_ANOMS"
waitUntil -k
clear

./whatChanged "$BBOX_ANOMS_OLD" "$BBOX_ANOMS"
waitUntil -k
clear

./whatChanged "$MHZ_ANOMS_OLD" "$MHZ_ANOMS"
waitUntil -k
clear

./whatChanged "$OPB_ANOMS_OLD" "$OPB_ANOMS"
waitUntil -k
clear

./whatChanged "$ADDOPB_ANOMS_OLD" "$ADDOPB_ANOMS"
waitUntil -k
clear

view "$ACORN_DIFFS" "$BBOX_DIFFS" "$MHZ_DIFFS" "$OPB_DIFFS" "$ADDOPB_DIFFS"

if waitUntil -cs "Save today's files for ALL services?"; then
    printf "==> Saving today's files...\n\n"
    ./saveTodaysAcornFiles.sh
    ./saveTodaysBBoxFiles.sh
    ./saveTodaysMHzFiles.sh
    ./saveTodaysOPBFiles.sh
else
    printf "==> Today's files not saved!\n"
    printf "Use these commands to save individual services:\n"
    cat <<EOF
  ./saveTodaysAcornFiles.sh
  ./saveTodaysBBoxFiles.sh
  ./saveTodaysMHzFiles.sh
  ./saveTodaysOPBFiles.sh

EOF
fi
