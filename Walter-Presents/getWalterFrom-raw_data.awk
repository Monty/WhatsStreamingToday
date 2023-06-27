# Grab fields from Walter Presents HTML files
# Title  Seasons  Episodes  Duration  Language Description

# Title  Seasons  Episodes  Duration  Genre  Country  Language  Rating  Description

# Title  Seasons  Episodes  Duration  Genre  Year  Rating  Description  Content_Type  Content_ID  Show_Type  Date_Type  Season_ID  Sn_#  Ep_#

/^https:/ {
    split ($0,fld,"\t")
    showURL = fld[1]
    # print "==> showURL = " showURL > "/dev/stderr"
    # Create shorter URL by removing https://
    shortURL = showURL
    sub (/.*pbs.org/,"pbs.org",shortURL)
    showTitle = fld[2]
    print showTitle >> RAW_TITLES
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
}

/ "description":/ {
    descriptionLinesFound++
    split ($0,fld,"\"")
    showDescription = fld[4]
    gsub (/&#x27;/,"'",showDescription)
    sub (/ with English subtitles/,"",showDescription)
    sub (/ From Walter Presents, in/," In",showDescription)
    # print showDescription
    next
}

# Don't include Previews
/Preview: S[0-9]* Ep[0-9]* \| / || /Preview: Ep[0-9]* \| / {
    next
}

# Don't include Clips
/Clip: S[0-9]* Ep[0-9]* \| / || /Clip: Ep[0-9]* \| / {
    next
}

/ S.[0-9]* Ep[0-9]* \| / {
    episodeLinesFound++
    durationLinesFound++
    next
}

/ Ep[0-9]* \| / {
    episodeLinesFound++
    durationLinesFound++
    next
}

/ [0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| / {
    episodeLinesFound++
    durationLinesFound++
    next
}


/-- start medium-rectangle-half-page --/ {
    if (episodeLinesFound == 0) {
        printf ("==> No episodes found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (episodeLinesFound == 1) {
        printf ("==> Only one episode: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (descriptionLinesFound == 0) {
        printf ("==> No description found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (durationLinesFound == 0) {
        printf ("==> No durations found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }


    printf ("%s\t%s\t%s\t%s\t%s\n", showLink, showSeasons, \
            episodeLinesFound, showDurationText, showDescription)
    # Make sure there is no carryover
    showURL = ""
    showTitle = ""
    showLink = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    showDuration = ""
    showDescription = ""
    #
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound  = 0
    durationLinesFound = 0
}
