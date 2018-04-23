# Print lines from a WebScraper csv file after joining extra newlines
# Make sure lines have a terminating double quote (except header line)

# INVOCATION:
#   awk -f fixExtraLinesFrom-webscraper.awk BritBoxPrograms.csv

{
    if (/^"/) {
        if (line !~ "\"$" && NR != 2)
            line = line "\""
        print line
        line = $0
    } else {
        line = line $0
    }
}

END {
    if (line !~ "\"$")
        line = line "\""
    print line
}
