# Create column files with lists of series titles, descriptions, number 
# of seasons, and number of episodes, to be pasted into a spreadsheet.
# Note that IN_CANADA affects processing.
#
# Create a separate file with a line for each episode containing
# seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
# episodeTitle, & episodeDuration with the same columns as the primary
# spreadsheet so they can be combined into one.
#
# Create a separate file with a line for each series duration
#
# Return the total duration of all series
#
# INVOCATION:
#       curl -s https://acorn.tv/192/ \
#           | awk -v TITLE_FILE=$TITLE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
#           -v NUM_SEASONS_FILE=$NUM_SEASONS_FILE -v NUM_EPISODES_FILE=$NUM_EPISODES_FILE \
#           -v EPISODE_CURL_FILE=$EPISODE_CURL_FILE -v IN_CANADA=$IN_CANADA \
#           -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$lastRow \
#           -v DURATION_FILE=$DURATION_FILE -v ERROR_FILE=$ERROR_FILE -f getAcornFrom-seriesPages.awk
#
# INPUT:
#        <title>Empire | Acorn TV</title>
#  ---
#        <span itemprop="name">Empire</span>
#        <meta itemprop="numberOfEpisodes" content="30" />
#        <meta itemprop="numberOfSeasons" content="3" />
#  ---
#        <meta itemprop="numberOfEpisodes" content="10" />
#        <meta itemprop="numberOfEpisodes" content="10" />
#        <meta itemprop="numberOfEpisodes" content="10" />
#  ---
#        <p id="franchise-description" itemprop="description">"The writing is sublime" (New \
#        York Times) in this anything-but-a-procedural cop drama ... as reluctant partners \
#        patrolling the streets of Montreal. Not Available in Canada. CC Available.</p>
#  ---
#        <p>We're sorry, but Acorn TV is not available in this territory.</p>
#  ---
#        <meta itemprop="seasonNumber" content="1" />
#  ---
#        <a itemprop="url" href="https://acorn.tv/192/series1/partners">
#  ---
#        <meta itemprop="timeRequired" content="T44M06S" />
#  ---
#        <h5 itemprop="name">Partners</h5>
#  ---
#        <h6>Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Season 9 Christmas Special: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Series 1: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Series 1 (Set 1): Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Series 10 (Sets 13 - 14): Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Series 19 (Part One): Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Set 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Mini Series: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Miniseries: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Black Widows Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>A Dance to the Music of Time: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Christmas Special : Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Feature Film: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <!-- Viewers Also Watched -->
#
#  OUTPUT:
#       $EPISODE_INFO_FILE
#

# Extract the series title
/span itemprop="name"/ {
    split ($0,fld,"[<>]")
    seriesTitle = fld[3]
    gsub (/&amp;/,"\\&",seriesTitle)
    gsub (/&quot;/,"\"\"",seriesTitle)
    gsub (/"/,"\"\"",seriesTitle)
    gsub (/&#039;/,"'",seriesTitle)
    gsub (/&#8217;/,"'",seriesTitle)
    gsub (/&#8211;/,"-",seriesTitle)
    # gsub (/&#x27;/,"'",seriesTitle)
    if (match (seriesTitle, /^The /)) {
        seriesTitle = substr(seriesTitle, 5) ", The"
    }
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound = 0
    durationLinesFound = 0
    numEpisodesStr = ""
    print seriesTitle >> TITLE_FILE
    next
}

# Extract the number of episodes in the series
/itemprop="numberOfEpisodes"/ {
    episodeLinesFound += 1
    split ($0,fld,"\"")
    if (episodeLinesFound == 1)
        totalEpisodes = fld[4]
    if (episodeLinesFound != 1)
        numEpisodesStr = numEpisodesStr "+" fld[4]
    next
}

# Extract the number of seasons in the series
/itemprop="numberOfSeasons"/ {
    seasonLinesFound += 1
    split ($0,fld,"\"")
    numSeasons = fld[4]
    if ((numSeasons + 0) == 0)
        printf ("==> No seasons: %d\t%s\n", SERIES_NUMBER, seriesTitle) >> ERROR_FILE
    print numSeasons >> NUM_SEASONS_FILE
    next
}

/Acorn TV is not available in this territory/ {
    printf ("==> Not available here: %d\t%s\n", SERIES_NUMBER, seriesTitle) >> ERROR_FILE
}

# Extract the series description
/id="franchise-description"/ {
    descriptionLinesFound += 1
    # get rid of boilerplate
    split ($0,fld,"[<>]")
    description = fld[3]
    # get rid of unnecessary characters and text
    gsub (/\\/,"",description)
    if (IN_CANADA != "yes") {
        sub (/Series [[:digit:]]* not available in Canada\./,"",description)
        sub (/Not [Aa]vailable in Canada\./,"",description)
        sub (/NOT AVAILABLE IN CANADA\./,"",description)
    }
    sub (/CC Available\. CC Available/,"CC Available",description)
    # fix sloppy input spacing
    sub (/\.CC Available/,". CC Available",description)
    gsub (/ \./,".",description)
    gsub (/  */," ",description)
    sub (/^ */,"",description)
    sub (/ *$/,"",description)
    # fix funky HTML characters
    gsub (/&quot;/,"\"\"",description)
    gsub (/&#39;/,"'",description)
    gsub (/&#039;/,"'",description)
    gsub (/&#8217;/,"'",description)
    # fix unmatched quotes
    numQuotes = gsub(/"/,"\"",description)
    if ((numQuotes % 2) == 1) {
        printf ("==> Changed unmatched quote (%d): %d\t%s\n", numQuotes, SERIES_NUMBER, \
                seriesTitle) >> ERROR_FILE
        description = description " \""
    }
    print description >> DESCRIPTION_FILE
    next
}

# Extract the seasonNumber
# Note that Acorn "season" numbers may not correspond to actual season numbers.
# They simply refer to the number of seasons available on Acorn.
/<meta itemprop="seasonNumber" content="/ {
    split ($0,fld,"\"")
    seasonNumber = fld[4]
    next
}

# Extract the episode URL
/<a itemprop="url"/ {
    split ($0,fld,"\"")
    episodeURL = fld[4]
    sub (/\/$/,"",episodeURL)
    # Create shorter URL by removing https://
    shortURL = episodeURL
    sub (/.*acorn\.tv/,"acorn.tv",shortURL)
    # Feature films don't have episodes
    if (episodeURL ~ /\/featurefilm\//)
        next
    # neither should single episode series
    if (totalEpisodes == 1)
        next
    print "url = \"" episodeURL "\"" >> EPISODE_CURL_FILE
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
    seriesSecs += secs
    seriesMins += mins + int(seriesSecs / 60)
    seriesHrs += hrs + int(seriesMins / 60)
    seriesSecs %= 60; seriesMins %= 60
    #
    totalSecs += secs
    totalMins += mins + int(totalSecs / 60)
    totalHrs += hrs + int(totalMins / 60)
    totalSecs %= 60; totalMins %= 60
    #
    episodeDuration = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (episodeDuration == "00:00:00")
        printf ("==> No duration: %s  %s\n", shortURL, seriesTitle) >> ERROR_FILE
    next
}

# Extract the episode title
/<h5 itemprop="name">/ {
    split ($0,fld,"[<>]")
    episodeTitle = fld[3]
    gsub (/&amp;/,"\\&", episodeTitle)
    gsub (/&#039;/,"'",episodeTitle)
    next
}

# There are a number of variants in the "episodeNumber" string
#
#       <h6>Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Season 9 Christmas Special: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Series 1: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Series 1 (Set 1): Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Series 10 (Sets 13 - 14): Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Series 19 (Part One): Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Set 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Mini Series: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Miniseries: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Black Widows Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>A Dance to the Music of Time: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Christmas Special : Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Feature Film: Episode <span itemprop="episodeNumber">1</span></h6>

# Extract episode number
/<h6>.*span itemprop="episodeNumber">/ {
    # If show is a Prequel, use "P"
    if (episodeURL ~ /\/prequel/)
        showType = "P"
    # If show is a Miniseries, use "M"
    if (episodeURL ~ /\/miniseries/)
        showType = "M"
    # If we don't know what kind of show it is, use "S"
    if (showType == "")
        showType = "S"
    # Default episodeType to "E"
    episodeType = "E"
    # Default bonus, parttwo, and christmas specials episodeType to "X"
    if (episodeURL ~ /\/bonus|[0-9]{1,2}parttwo\/|christmas[-]?special/)
        episodeType = "X"
    # If episode is a Trailer, set episodeType to "T"
    if (episodeURL ~ /\/trailer/)
        episodeType = "T"
    # jamaicainn, newworlds & newtonslaw bonus or trailer seasonNumber should be 1
    if (episodeURL ~ \
        /\/jamaicainn\/bonus\/|\/jamaicainn\/trailer\/|\/newworlds\/bonus\/|\/newtonslaw\/bonus\// \
        && seasonNumber != 1) {
        split (episodeURL, part, "/")
        printf ("==> Changed S%02d to S01: acorn.tv/%s/%s\n", \
               seasonNumber, part[4], part[5]) >> ERROR_FILE
        seasonNumber = 1
    }
    # Plain christmasspecial, seriesfinale don't increment seasonNumber
    if (episodeURL ~ /\/christmasspecial\/|\/seriesfinale\//) {
        split (episodeURL, part, "/")
        printf ("==> Changed S%02d to S%02d: acorn.tv/%s/%s\n", \
               seasonNumber, seasonNumber-1, part[4], part[5]) >> ERROR_FILE
        seasonNumber -= 1
    }
    #
    split ($0,fld,"[<>]")
    episodeNumber = fld[5]
    # Feature films don't have episodes
    if (episodeURL ~ /\/featurefilm\//)
        next
    # neither should single episode series
    if (totalEpisodes == 1)
        next
    # The season number should match that in the URL
    # Birds of a Feather, Doc Martin, Murdoch, Poirot, Rebus, Vera, and others have problems
    if (episodeURL ~ \
           /\/series[0-9]{1,2}\/|[0-9]{1,2}bonus\/|[0-9]{1,2}parttwo\/|\/murdoch\/season[0-9]{1,2}/) {
        split (episodeURL, part, "/")
        URLseasonNumber = part[5]
        sub (/bonus/,"",URLseasonNumber)
        # Foyle's War has sets: foyleswar/series9set8bonus/
        sub (/set[0-9]/,"",URLseasonNumber)
        # Midsomer Murders has two parts: midsomermurders/series19parttwo/
        sub (/parttwo/,"",URLseasonNumber)
        sub (/christmasspecial/,"",URLseasonNumber)
        sub (/[[:alpha:]]*/,"",URLseasonNumber)
        if (URLseasonNumber != seasonNumber) {
            printf ("==> Changed S%02d to S%02d: acorn.tv/%s/%s\n", \
               seasonNumber, URLseasonNumber, part[4], part[5]) >> ERROR_FILE
            seasonNumber = URLseasonNumber
        }
    }

    if ((episodeNumber + 0) == 0)
        print "==> Episode number is 00: " shortURL >> ERROR_FILE
    printf ("%d\t=HYPERLINK(\"%s\";\"%s, %s%02d%s%02d, %s\"\)\t\t\t%s\n", \
        SERIES_NUMBER, episodeURL, seriesTitle, showType, seasonNumber, episodeType, episodeNumber, \
        episodeTitle, episodeDuration) >> EPISODE_INFO_FILE
    showType = ""
    next
}

/<footer>/ {
    if (episodeLinesFound == 0) {
        print 0  >> NUM_EPISODES_FILE
        printf ("==> No numberOfEpisodes: %d\t%s\n", SERIES_NUMBER, seriesTitle) >> ERROR_FILE
    } else {
        print (episodeLinesFound == 1 ? "=0" : "=" numEpisodesStr) >> NUM_EPISODES_FILE
    }
    #
    if (seasonLinesFound == 0) {
        print seasonLinesFound >> NUM_SEASONS_FILE
        printf ("==> No numberOfSeasons: %d\t%s\n", SERIES_NUMBER, seriesTitle) >> ERROR_FILE
    }
    #
    if (descriptionLinesFound == 0) {
        print "-- No Description --" >> DESCRIPTION_FILE
        printf ("==> No franchise-description: %d\t%s\n", SERIES_NUMBER, seriesTitle) >> ERROR_FILE
    } else {
        if (description == "")
            printf ("==> No description: %d\t%s  %s\n", SERIES_NUMBER, shortURL, \
                    seriesTitle) >> ERROR_FILE
    }
    description = ""
    #
    if (durationLinesFound == 0) {
        print "00:00:00"  >> DURATION_FILE
        printf ("==> No timeRequired: %d\t%s\n", SERIES_NUMBER, seriesTitle) >> ERROR_FILE
    } else {
        seriesDuration = sprintf ("%02d:%02d:%02d", seriesHrs, seriesMins, seriesSecs)
        print seriesDuration >> DURATION_FILE
        if (seriesDuration == "00:00:00")
            printf ("==> No duration: %d\t%s  %s\n", SERIES_NUMBER, shortURL, i\
                    seriesTitle) >> ERROR_FILE
   }
    seriesSecs = 0
    seriesMins = 0
    seriesHrs = 0
    seriesDuration = ""
    #
    SERIES_NUMBER += 1
}

END {
    # Return the total duration of all series
    printf ("%02d:%02d:%02d\n", totalHrs, totalMins, totalSecs)
}
