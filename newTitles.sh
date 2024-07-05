#!/usr/bin/env bash
#
# prettydiff the most recent uniqTitles files from MHz, Acorn, OPB, and Britbox

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

while getopts ":b:" opt; do
    case $opt in
    b)
        BACK="$OPTARG"
        ;;
    :)
        printf "Option -$OPTARG requires a numeric argument specifying " >&2
        printf "the nth newest release to use.\n" >&2
        exit 1
        ;;
    *)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    esac
done

# Default to using the second oldest release
BACK="${BACK:-2}"
if [[ $BACK -lt 2 ]]; then
    BACK=2
fi

# shellcheck disable=SC1091 # waitUntil.function is a local file
source waitUntil.function

ACORN_TITLES=$(find Acorn_uniqTitles-*txt | tail -1)
ACORN_TITLES_OLD=$(find Acorn_uniqTitles-*txt | tail -"$BACK" | head -1)
#
BBOX_TITLES=$(find BBox_uniqTitles-*txt | tail -1)
BBOX_TITLES_OLD=$(find BBox_uniqTitles-*txt | tail -"$BACK" | head -1)
#
MHZ_TITLES=$(find MHz_uniqTitles-*txt | tail -1)
MHZ_TITLES_OLD=$(find MHz_uniqTitles-*txt | tail -"$BACK" | head -1)
#
OPB_TITLES=$(find OPB_uniqTitles-*txt | tail -1)
OPB_TITLES_OLD=$(find OPB_uniqTitles-*txt | tail -"$BACK" | head -1)

# First as a table with both new and removed
printf "\n==> Show new titles since $MHZ_TITLES_OLD"
if waitUntil -Y "?"; then
    prettydiff "$MHZ_TITLES_OLD" "$MHZ_TITLES"
fi

printf "\n==> Show new titles since $ACORN_TITLES_OLD"
if waitUntil -Y "?"; then
    prettydiff "$ACORN_TITLES_OLD" "$ACORN_TITLES"
fi

printf "\n==> Show new titles since $OPB_TITLES_OLD"
if waitUntil -Y "?"; then
    prettydiff "$OPB_TITLES_OLD" "$OPB_TITLES"
fi

printf "\n==> Show new titles since $BBOX_TITLES_OLD"
if waitUntil -Y "?"; then
    prettydiff "$BBOX_TITLES_OLD" "$BBOX_TITLES"
fi

printf '\n==> Show all new titles as plain text'
if waitUntil -Y "?"; then
    printf "\nNew titles since $MHZ_TITLES_OLD:\n"
    zet diff "$MHZ_TITLES" "$MHZ_TITLES_OLD" | sed "s/^/    /g"

    printf "\nNew titles since $ACORN_TITLES_OLD:\n"
    zet diff "$ACORN_TITLES" "$ACORN_TITLES_OLD" | sed "s/^/    /g"

    printf "\nNew titles since $OPB_TITLES_OLD:\n"
    zet diff "$OPB_TITLES" "$OPB_TITLES_OLD" | sed "s/^/    /g"

    printf "\nNew titles since $BBOX_TITLES_OLD:\n"
    zet diff "$BBOX_TITLES" "$BBOX_TITLES_OLD" | sed "s/^/    /g"
fi

printf "\n"
