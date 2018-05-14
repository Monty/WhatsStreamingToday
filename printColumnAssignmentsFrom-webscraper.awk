# Print field numbers and field names from a WebScraper csv file saved in tsv format

# INVOCATION:
#   awk -f printFieldNamesFrom-webscraper.awk -v maxRecordsToPrint=5 BritBoxSeasons-test-tabs.csv

BEGIN {
    FS="\t"
    # print 3 records unless overridden with "-v maxRecordsToPrint=<n>"
    if (maxRecordsToPrint == "") maxRecordsToPrint = 1
}

NR <= maxRecordsToPrint {
    gsub (/-/,"_")
    for ( i = 1; i <= NF; i++ ) {
        print "    " $i " = $" i
    }
    print ""
}
