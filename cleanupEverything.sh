#!/usr/bin/env bash
# Remove all files and directories created by running scripts

printf "Answer y to delete, anything else to skip. Deletion cannot be undone!\n"
printf "\n"

# Allow switches -v or -i to be passed to the rm command
while getopts ":iv" opt; do
    case $opt in
    i)
        ASK="-i"
        ;;
    v)
        TELL="-v"
        ;;
    \?)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    esac
done
shift $((OPTIND - 1))

# Ask $1 first, shift, then rm $@
function yesnodelete() {
    read -r -p "Delete $1? [y/N] " YESNO
    shift
    if [ "$YESNO" != "y" ]; then
        printf "Skipping...\n"
    else
        printf "Deleting ...\n"
        # Don't quote $@. Globbing needs to take place here.
        rm -rf $ASK $TELL $@
    fi
    printf "\n"
}

# Quote filenames so globbing takes place in the "rm" command itself,
# i.e. the function is passed the number of parameters seen below, not
# the expanded list which could be quite long.
yesnodelete "all primary spreadsheet files" "Acorn_TV_Shows*.csv" "MHz_TV_Shows*.csv" \
    "BBox_TV_Shows*.csv"
yesnodelete "all secondary spreadsheet files" "Acorn-columns" "MHz-columns" "BBox-columns"
yesnodelete "all anomalies reports" "Acorn_anomalies*.txt" "MHz_anomalies*.txt" \
    "BBox_anomalies*.txt"
yesnodelete "all diff results" "Acorn_diffs*.txt" "MHz_diffs*.txt" "BBox_diffs*.txt"
yesnodelete "all diff baselines" "Acorn-baseline" "MHz-baseline" "BBox-baseline"
