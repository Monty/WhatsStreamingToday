#! /bin/bash
# Create a human readable diff of any two "TV spreadsheets" from the same streaming service
#     ./whatsChanged.sh [-b] oldSpreadsheet newSpreadsheet
#
#     -b brief. Don't output the diffs, just list what was done, e.g.
#           ==> 2 insertions, 1 deletion, 1 modification
#           deleted 1 show at line 35
#           added 2 shows after line 98
#           changed 1 show at line 101
#
#     -s summary. Only output the diffstat summary line, e.g.
#           ==> 10 insertions, 10 deletions, 6 modifications
#
#  It's a specialized diff that only looks at lines starting with "=HYPERLINK"
#  It will likely report no diffs on any files not in "TV spreadsheet" format

# Only keep lines containing "=HYPERLINK" then get rid of leading sequence numbers
function sanitize() {
    sed -e /=HYPER/!D -e /=HYPER/s/^.*=HYPER/=HYPER/ "$1"
}

while getopts ":bs" opt; do
    case $opt in
    b)
        BRIEF="yes"
        ;;
    s)
        SUMMARY="yes"
        ;;
    \?)
        echo "Ignoring invalid option: -$OPTARG" >&2
        ;;
    esac
done
shift $((OPTIND - 1))

echo "==> changes between $1 and $2:"
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
        echo "==> nothing changed"
    fi
else
    if checkdiffs <(sanitize "$1") <(sanitize "$2"); then
        echo "==> nothing changed"
    fi
fi
