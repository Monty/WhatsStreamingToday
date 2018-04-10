# Print lines from a WebScraper csv file after joining extra newlines

# INVOCATION:
#   awk -f fixExtraLinesFrom-webscraper.awk BritBoxPrograms.csv

{
    if (/^"/)
        printf ("\n" $0)
    else
        printf
}
