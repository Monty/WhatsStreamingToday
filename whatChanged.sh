#! /bin/bash
# Create a human readable diff of any two "TV spreadsheets" from the same streaming service
#     ./whatsChanged.sh [-b] oldSpreadsheet newSpreadsheet
#
#     -b brief. Don't output the diffs, just summarize what was done, e.g.
#           deleted 1 show at line 35
#           added 2 shows after line 98
#           changed 1 show at line 101
#
#  It's a specialized diff that only looks at lines starting with "=HYPERLINK"
#  It will likely report no diffs on any files not in "TV spreadsheet" format

# "cat" provides a no-op for a pipe
PIPE_TO="cat"
while getopts ":b" opt; do
    case $opt in
        b)
            # Only print lines beginning with ==>
            # but delete the ==> and terminating :
            # since that looks better in this context
            PIPE_TO="sed -e /^==>/!D -e s/^==>// -e s/://"
            ;;
        \?)
            echo "Ignoring invalid option: -$OPTARG" >&2
            ;;
    esac
done
shift $((OPTIND - 1))

echo "==> what changed between $1 and $2:"
# first the stats
diff -c $1 $2 | diffstat -s \
    -D $(cd "$(dirname "$2")" && pwd -P) \
    | sed -e "s/ 1 file changed,/==>/" -e "s/([+-=\!])//g"
# then the diffs
diff \
    --unchanged-group-format='' \
    --old-group-format='==> deleted %dn show%(n=1?:s) at line %df:
%<' \
    --new-group-format='==> added %dN show%(N=1?:s) after line %de:
%>' \
    --changed-group-format='==> changed %dn show%(n=1?:s) at line %df:
%<------ to:
%>' <(grep ^=HYPERLINK $1) <(grep ^=HYPERLINK $2) | $PIPE_TO
