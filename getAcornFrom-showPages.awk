# Produce a raw data spreadsheet from URLs found in $SHOW_URLS
#
# Note that IN_CANADA affects processing.
#
# INVOCATION:
#    while read -r line; do
#        curl -sS "$line" |
#            awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES v LONG_SPREADSHEET=$LONG_SPREADSHEET \
#            -v EPISODE_URLS=$EPISODE_URLS -f getAcornFrom-showPages.awk >>$UNSORTED
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
    # print "==> showTitle = " showTitle > "/dev/stderr"
    next
}

# Extract the show URL
/meta property="og:url/ {
    split ($0,fld,"\"")
    showURL = fld[4]
    # print "==> showURL = " showURL > "/dev/stderr"
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
        # print "==> showEpisodes = " showEpisodes " " shortURL > "/dev/stderr"
    }
    if (episodeLinesFound != 1) {
        seasonEpisodes = seasonEpisodes "+" fld[4]
        if (seasonEpisodes == "") {
            printf ("==> Blank seasonEpisodes in numberOfEpisodes: %s\t%s\n", shortURL, showTitle) >> ERRORS
        }
        # print "==> seasonEpisodes = " seasonEpisodes " " shortURL > "/dev/stderr"
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
    # print "==> showSeasons = " showSeasons " " shortURL > "/dev/stderr"
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
        printf ("==> Changed unmatched quote (%d): %d\t%s\t%s\t%s\n", numQuotes, shortURL,
                showTitle) >> ERRORS
        showDescription = showDescription " \""
    }
    # print "==> showDescription = " showDescription " " shortURL > "/dev/stderr"
    next
}

# Extract the seasonNumber
# Note that Acorn "season" numbers may not correspond to actual season numbers.
# They simply refer to the number of seasons available on Acorn.
/<meta itemprop="seasonNumber" content="/ {
    split ($0,fld,"\"")
    seasonNumber = fld[4]
    # print "==> seasonNumber = " seasonNumber " " shortURL > "/dev/stderr"
    next
}

# Extract the episode URL
/<a itemprop="url"/ {
    split ($0,fld,"\"")
    episodeURL = fld[4]
    # print "==> episodeURL = " episodeURL > "/dev/stderr"
    print episodeURL >> EPISODE_URLS
    shortEpisodeURL = episodeURL
    sub (/.*acorn\.tv/,"acorn.tv",shortEpisodeURL)
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
    # print "==> episodeDuration = " episodeDuration " " shortEpisodeURL > "/dev/stderr"
    if (episodeDuration == "00:00:00")
        printf ("==> Blank episode duration: %s  %s\n", shortEpisodeURL, showTitle) >> ERRORS
    next
}

# Extract the episode title
/<h5 itemprop="name">/ {
    split ($0,fld,"[<>]")
    episodeTitle = fld[3]
    gsub (/&amp;/,"\\&", episodeTitle)
    gsub (/&#039;/,"'",episodeTitle)
    # print "==> episodeTitle = " episodeTitle " " shortEpisodeURL > "/dev/stderr"
    next
}

# Extract episode number
/<h6>.*span itemprop="episodeNumber">/ {
    split ($0,fld,"[<>]")
    episodeNumber = fld[5]
    # print "==> episodeNumber = " episodeNumber " " shortEpisodeURL > "/dev/stderr"
    # 
    # Setup showType so shows group/sort properly
    # Default showType to "S"
    showType = "S"
    # If show is a Prequel, use "P" e.g. Doc Martin
    if (episodeURL ~ /\/prequel/)
        showType = "P"
    # 
    # Setup episodeType so episodes group/sort properly
    # Default episodeType to "E"
    episodeType = "E"
    # Default bonus and christmas specials episodeType to "X"
    if (episodeURL ~ /\/bonus|christmas[-]?special/)
        episodeType = "X"
    # If episode is a Trailer, set episodeType to "T" - even though not all these have episodes
    if (episodeURL ~ /_cs\//)
        episodeType = "T"
    #
    # cryptoftears, newworlds & newtonslaw bonus seasonNumber should be 1
    if (episodeURL ~ \
        /\/cryptoftears\/bonus\/|\/newworlds\/bonus\/|\/newtonslaw\/bonus\// \
        && seasonNumber != 1) {
            printf ("==> Changed S%02d to S01: %s\n", seasonNumber, shortEpisodeURL) >> ERRORS
        seasonNumber = 1
    }
    # Plain christmasspecial, seriesfinale don't increment seasonNumber
    if (episodeURL ~ /\/christmasspecial\/|\/seriesfinale\//) {
        printf ("==> Changed S%02d to S%02d: %s\n", seasonNumber, seasonNumber-1, 
                shortEpisodeURL) >> ERRORS
        seasonNumber -= 1
    }
    # Wrap up this episode
    # =HYPERLINK("https://acorn.tv/1900island/series1/week-one";"1900 Island, S01E01, Week One")
    episodeLink = sprintf ("=HYPERLINK(\"%s\";\"%s, %s%02d%s%02d, %s\"\)", episodeURL, showTitle,
                    showType, seasonNumber, episodeType, episodeNumber, episodeTitle)
    # Print "episode" line
    # =HYPERLINK("https://acorn.tv/1900island/series1/week-one";"1900 Island, S01E01, Week One") \
    # \t\t\t 00:59:17 \t As they arrive
        printf ("%s\t\t\t%s\t%s\n", episodeLink, episodeDuration, episodeDescription) >> LONG_SPREADSHEET
    episodeURL = ""
    episodeType = ""
    episodeTitle = ""
    episodeNumber = ""
    episodeDuration = ""
    next
}

# Wrap up this show
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
