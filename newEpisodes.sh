#!/usr/bin/env bash
#
# diff the most recent TV_ShowsEpisodes files from MHz, Acorn, OPB, and Britbox
# and print the new episodes
#
# Assume episodes have a season mumber in field 1, i.e. ', S[0-9][0-9]'

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

while getopts ":ab:" opt; do
    case $opt in
    a)
        ASKFIRST="yes"
        ;;
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

ACORN_EPISODES=$(find Acorn_TV_ShowsEpisodes-*csv | tail -1)
ACORN_EPISODES_OLD=$(find Acorn_TV_ShowsEpisodes-*csv | tail -"$BACK" | head -1)
#
BBOX_EPISODES=$(find BBox_TV_ShowsEpisodes-*csv | tail -1)
BBOX_EPISODES_OLD=$(find BBox_TV_ShowsEpisodes-*csv | tail -"$BACK" | head -1)
#
MHZ_EPISODES=$(find MHz_TV_ShowsEpisodes-*csv | tail -1)
MHZ_EPISODES_OLD=$(find MHz_TV_ShowsEpisodes-*csv | tail -"$BACK" | head -1)
#
OPB_EPISODES=$(find OPB_TV_ShowsEpisodes-*csv | tail -1)
OPB_EPISODES_OLD=$(find OPB_TV_ShowsEpisodes-*csv | tail -"$BACK" | head -1)

function printNewAcornEpisodes() {
    zet diff \
        <(rg -v 'Coming Soon|/comingsoon|/placeholder' \
            "$ACORN_EPISODES" | cut -f 1 | rg ', [SMP][0-9]{2}' |
            awk -f printTitles.awk) \
        <(rg -v 'Coming Soon|/comingsoon|/placeholder' \
            "$ACORN_EPISODES_OLD" | rg ', [SMP][0-9]{2}' |
            awk -f printTitles.awk)
}

function printNewBBoxEpisodes() {
    zet diff \
        <(cut -f 1 "$BBOX_EPISODES" | rg ', S[0-9]{2}|/movie' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$BBOX_EPISODES_OLD" | rg ', S[0-9]{2}|/movie' |
            awk -f printTitles.awk) |
        rg -v "Coming Soon|Coronation Street|Doctors|EastEnders|Emmerdale" |
        rg -v "Good Morning Britain|Landward|Question Time|Casualty" |
        rg -v "QI,|RHS Chelsea Flower Show|The Beechgrove Garden|Jonathan Ross" |
        rg -v "Escape to the Country|Gardeners' World|Prime Minister's Questions"
}

function printNewMHzEpisodes() {
    zet diff \
        <(cut -f 1 "$MHZ_EPISODES" | rg ', S[0-9]{2}' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$MHZ_EPISODES_OLD" | rg ', S[0-9]{2}' |
            awk -f printTitles.awk) | rg -v ', $' |
        rg -v ' Available |, S[0-9]{2}T[0-9]{2}'
}

function printNewOPBEpisodes() {
    zet diff \
        <(cut -f 1 "$OPB_EPISODES" | rg ', S[0-9]{2}' |
            awk -f printTitles.awk) \
        <(cut -f 1 "$OPB_EPISODES_OLD" | rg ', S[0-9]{2}' |
            awk -f printTitles.awk)
}

if [ "$ASKFIRST" != "yes" ]; then
    printf "==> Show new episodes since $MHZ_EPISODES_OLD? [Y/n]\n"
    printNewMHzEpisodes
    #
    printf "\n==> Show new episodes since $ACORN_EPISODES_OLD? [Y/n]\n"
    printNewAcornEpisodes
    #
    printf "\n==> Show new episodes since $OPB_EPISODES_OLD? [Y/n]\n"
    printNewOPBEpisodes
    #
    printf "\n==> Show new episodes since $BBOX_EPISODES_OLD? [Y/n]\n"
    printNewBBoxEpisodes
else
    printf "==> Show new episodes since $MHZ_EPISODES_OLD"
    if waitUntil -Y "?"; then
        printNewMHzEpisodes
    fi
    #
    printf "\n==> Show new episodes since $ACORN_EPISODES_OLD"
    if waitUntil -Y "?"; then
        printNewAcornEpisodes
    fi
    #
    printf "\n==> Show new episodes since $OPB_EPISODES_OLD"
    if waitUntil -Y "?"; then
        printNewOPBEpisodes
    fi
    #
    printf "\n==> Show new episodes since $BBOX_EPISODES_OLD"
    if waitUntil -Y "?"; then
        printNewBBoxEpisodes
    fi
fi
