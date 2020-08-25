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

# Only keep lines containing "=HYPERLINK" then get rid of leading sequence numbers
# Only keep fields 1-3 unless -l is specified
function sanitize() {
    sed -e /=HYPER/!D -e /=HYPER/s/^.*=HYPER/=HYPER/ "$1" | cut -f 1-3"${LONG}"
}

printf "==> changes between $1 and $2:\n"
# first the stats
diff -c <(sanitize "$1") <(sanitize "$2") | diffstat -sq |
    sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
if [ "$SUMMARY" = "yes" ]; then
    exit
fi

# Now the diffs
function checkdiffs() {
    diff \
        --unchanged-group-format='' \
        --old-group-format='#   ==> deleted %dn show%(n=1?:s) at line %df <==
%<' \
        --new-group-format='#   ==> added %dN show%(N=1?:s) after line %de <==
%>' \
        --changed-group-format='#   ==> changed %dn show%(n=1?:s) at line %df <==
%<------ to:
%>' "$1" "$2"
}

if [ "$BRIEF" = "yes" ]; then
    # Only print lines beginning with "#   ==>"
    # but delete the "#   ==>" and terminating "<=="
    # since that looks better in this context
    checkdiffs <(sanitize "$1") <(sanitize "$2") |
        sed -e "/#   ==>/!D" -e "s/#   ==> /    /" -e "s/ <==//"
    if [ ${PIPESTATUS[0]} == 0 ]; then
        printf "==> nothing changed.\n"
    fi
else
    if checkdiffs <(sanitize "$1") <(sanitize "$2"); then
        printf "==> nothing changed.\n"
    fi
fi
