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
    # Create shorter URL by removing https://
    shortURL = showURL
    sub (/.*acorn\.tv/,"acorn.tv",shortURL)
    next
}

# Extract the number of episodes in the show
/itemprop="numberOfEpisodes"/ {
    episodeLinesFound += 1
    split ($0,fld,"\"")
    if (episodeLinesFound == 1) {
        showEpisodes = fld[4]
        # print "==> showEpisodes = " showEpisodes " -- " FILENAME > "/dev/stderr"
    }
    if (episodeLinesFound != 1) {
        seasonEpisodes = seasonEpisodes "+" fld[4]
        # print "==> seasonEpisodes = " seasonEpisodes " -- " FILENAME > "/dev/stderr"
    }
    next
}

# Extract the number of seasons in the show
/itemprop="numberOfSeasons"/ {
    seasonLinesFound += 1
    split ($0,fld,"\"")
    showSeasons = fld[4]
    if ((showSeasons + 0) == 0) {
        printf ("==> No seasons in numberOfSeasons: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    # print "==> showSeasons = " showSeasons " -- " FILENAME > "/dev/stderr"
    next
}

# Extract the show description
/id="franchise-description"/ {
    descriptionLinesFound += 1
    # get rid of boilerplate
    split ($0,fld,"[<>]")
    showDescription = fld[3]
    # get rid of unnecessary characters and text
    sub (/ Not available in Canada\./,"",showDescription)
    # fix sloppy input spacing
    gsub (/ \./,".",showDescription)
    gsub (/  */," ",showDescription)
    # sub (/^ */,"",showDescription)
    sub (/ *$/,"",showDescription)
    # fix funky HTML characters
    gsub (/&amp;/,"\\&",showDescription)
    gsub (/&quot;/,"\"\"",showDescription)
    gsub (/&#039;/,"'",showDescription)
    # fix unmatched quotes
    numQuotes = gsub(/"/,"\"",showDescription)
    if ((numQuotes % 2) == 1) {
        printf ("==> Changed unmatched quote (%d): %d\t%s\t%s\t%s\n", numQuotes, shortURL, \
                showTitle) >> ERRORS
        showDescription = showDescription " \""
    }
    # print "==> showDescription = " showDescription " -- " FILENAME > "/dev/stderr"
    next
}

/<footer>/ {
    if (episodeLinesFound == 0) {
        printf ("==> No numberOfEpisodes: %s\t%s\n", shortURL, showTitle) >> ERRORS
        showEpisodes = 0
    }
    if (seasonLinesFound == 0) {
        printf ("==> No numberOfSeasons: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (descriptionLinesFound == 0) {
        printf ("==> No franchise-description: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    # Title	Seasons	Episodes	Duration	Description
    printf ("%s\t%s\t=%s\t%s\n", showLink, showSeasons, seasonEpisodes, showDescription)
    # printf ("%s\t%s\t=%s\t%s\t%s\n", showLink, showSeasons, seasonEpisodes, showDuration, showDescription)
    # printf ("%s\t%s\t=%s\t%s\t%s\n", showLink, showSeasons, showEpisodes, showDuration, showDescription)
    # Make sure there is no carryover
    showTitle = ""
    showURL = ""
    shortURL = ""
    showLink = ""
    showSeasons = ""
    showEpisodes = ""
    seasonEpisodes = ""
    showDuration = ""
    showDescription = ""
    #
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound  = 0
}
