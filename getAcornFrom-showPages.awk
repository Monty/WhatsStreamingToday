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
        if (showEpisodes == "") {
            printf ("==> Blank showEpisodes in numberOfEpisodes: %s\t%s\n", shortURL, showTitle) >> ERRORS
        }
        # print "==> showEpisodes = " showEpisodes " -- " FILENAME > "/dev/stderr"
    }
    if (episodeLinesFound != 1) {
        seasonEpisodes = seasonEpisodes "+" fld[4]
        if (seasonEpisodes == "") {
            printf ("==> Blank seasonEpisodes in numberOfEpisodes: %s\t%s\n", shortURL, showTitle) >> ERRORS
        }
        # print "==> seasonEpisodes = " seasonEpisodes " -- " FILENAME > "/dev/stderr"
    }
    next
}

# Extract the number of seasons in the show
/itemprop="numberOfSeasons"/ {
    seasonLinesFound += 1
    split ($0,fld,"\"")
    showSeasons = fld[4]
    if (showSeasons == "") {
        printf ("==> Blank showSeasons in numberOfSeasons: %s\t%s\n", shortURL, showTitle) >> ERRORS
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
    # fix sloppy input spacing
    gsub (/ \./,".",showDescription)
    gsub (/  */," ",showDescription)
    sub (/^ */,"",showDescription)
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

# Extract the episode duration
/<meta itemprop="timeRequired"/ {
    durationLinesFound += 1
    split ($0,fld,"\"")
    split (fld[4],tm,/[TMS]/)
    secs = tm[3]
    mins = tm[2] + int(secs / 60)
    hrs =  int(mins / 60)
    secs %= 60; mins %= 60
    #
    showSecs += secs
    showMins += mins + int(showSecs / 60)
    showHrs += hrs + int(showMins / 60)
    showSecs %= 60; showMins %= 60
    #
    episodeDuration = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (episodeDuration == "00:00:00")
        printf ("==> Blank episode duration: %s  %s\n", shortURL, showTitle) >> ERRORS
    next
}

/<footer>/ {
    if (episodeLinesFound == 0) {
        printf ("==> No numberOfEpisodes: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (seasonLinesFound == 0) {
        printf ("==> No numberOfSeasons: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (descriptionLinesFound == 0) {
        printf ("==> No franchise-description: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (durationLinesFound == 0) {
        printf ("==> No durations: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    showDuration = sprintf ("%02d:%02d:%02d", showHrs, showMins, showSecs)
    # Title	Seasons	Episodes	Duration	Description
    printf ("%s\t%s\t=%s\t%s\t%s\n", showLink, showSeasons, seasonEpisodes, showDuration, showDescription)
    # printf ("%s\t%s\t=%s\t%s\t%s\n", showLink, showSeasons, showEpisodes, showDuration, showDescription)
    # Make sure there is no carryover
    showTitle = ""
    showURL = ""
    shortURL = ""
    showLink = ""
    showSeasons = ""
    showEpisodes = ""
    seasonEpisodes = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    showDuration = ""
    showDescription = ""
    #
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound  = 0
}
