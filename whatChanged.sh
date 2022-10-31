#!/usr/bin/env bash
# Create a human readable diff of any two "TV spreadsheets" from the same streaming service
#     ./whatsChanged.sh [-b] oldSpreadsheet newSpreadsheet
#
#     -b brief. Don't output the diffs, just list what was done, e.g.
#           ==> 2 insertions, 1 deletion, 1 modification
#           deleted 1 show at line 35
#           added 2 shows after line 98
#           changed 1 show at line 101
#
#     -l long. Output descriptions, too. More detail, but harder to read.
#
#     -s summary. Only output the diffstat summary line, e.g.
#           ==> 10 insertions, 10 deletions, 6 modifications
#
#  It's a specialized diff that only looks at lines starting with "=HYPERLINK"
#  It will likely report no diffs on any files not in "TV spreadsheet" format

while getopts ":bls" opt; do
    case $opt in
    b)
        BRIEF="yes"
        ;;
    l)
        # Find the field number of the Description (last) field
        DESCRIPTION=$(head -1 "${@: -1}" | awk '{print NF-1}')
        LONG=",$DESCRIPTION"
        ;;
    s)
        SUMMARY="yes"
        ;;
    \?)
        printf "Ignoring invalid option: -$OPTARG\n" >&2
        ;;
    esac
done
shift $((OPTIND - 1))

printf "==> changes between $1 and $2:\n"
# first the stats
diff -u "$1" "$2" | diffstat -sq \
    -D $(cd $(dirname "$2") && pwd -P) |
    sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
if [ "$SUMMARY" = "yes" ]; then
    exit
fi

# Now the diffs
function checkdiffs() {
    cmp --quiet "$1" "$2"
    if [ $? == 0 ]; then
        printf "==> no diffs found.\n"
    else
        diff -U 0 "$1" "$2" |
            diffr --colors refine-added:foreground:none --colors refine-removed:foreground:none |
            awk -f formatUnifiedDiffOutput.awk
    fi
}

if [ "$BRIEF" = "yes" ]; then
    # Only print lines beginning with "==>"
    # but delete the "==>"
    # since that looks better in this context
    checkdiffs "$1" "$2" |
        sed -e "/==>/!D" -e "s/==> /    /"
else
    checkdiffs "$1" "$2"
fi
