# Produce a raw data spreadsheet from URLs found in $SHOW_URLS
#
# Note that IN_CANADA affects processing.
#
# INVOCATION:
#    while read -r line; do
#        curl -sS "$line" |
#            awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES -f getAcornFrom-showPages.awk >>$UNSORTED
#        ((lastRow++))
#    done <"$SHOW_URLS"

#   Field Names
#        1 Title (link)    2 Seasons    3 Episodes    4 Duration    5 Description

# Extract the show title
/meta property="og:title/ {
    split ($0,fld,"\"")
    showTitle = fld[4]
    sub (/^Watch /,"",showTitle)
    sub (/ on Acorn TV$/,"",showTitle)
    gsub (/&amp;/,"\\&",showTitle)
    gsub (/&quot;/,"\"\"",showTitle)
    gsub (/&#039;/,"'",showTitle)
    # gsub (/&#8217;/,"'",showTitle)
    # gsub (/&#8211;/,"-",showTitle)
    # gsub (/&#x27;/,"'",showTitle)
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }
    print showTitle >> RAW_TITLES
    # print "==> showTitle = " showTitle " -- " FILENAME > "/dev/stderr"
    next
}

# Extract the show URL
/meta property="og:url/ {
    split ($0,fld,"\"")
    showURL = fld[4]
    # print "==> showURL = " showURL " -- " FILENAME > "/dev/stderr"
    next
}

/<footer>/ {
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    printf ("%s\n", showLink)
    # Title	Seasons	Episodes	Duration	Description
    # printf ("%s\t%s\t\t\t\t\t%s\n", showLink, showSeasons, showEpisodes, showDuration, showDescriptor)
    # Make sure there is no carryover
    showTitle = ""
    showURL = ""
    showLink = ""
    showSeasons = ""
    showEpisodes = ""
    showDuration = ""
    showDescriptor = ""
}
