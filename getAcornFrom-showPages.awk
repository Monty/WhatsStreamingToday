# Produce a raw data spreadsheet from URLs found in $SHOW_URLS
#
# Note that IN_CANADA affects processing.
#
# INVOCATION:
#    while read -r line; do
#        curl -sS "$line" |
#            awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES -v EPISODE_URLS=$EPISODE_URLS \
#                -v DURATION=$DURATION -v SHORT_SPREADSHEET=$SHORT_SPREADSHEET \
#                -f getAcornFrom-showPages.awk >$UNSORTED
#    done <"$SHOW_URLS"

#   Field Names
#        1 Title (link)    2 Seasons    3 Episodes    4 Duration    5 Description

# Extract the show title
/meta property="og:title/ {
    totalShows += 1
    split($0,fld,"\"")
    showTitle = fld[4]
    sub(/^Watch /,"",showTitle)
    sub(/ [Oo]n Acorn TV$/,"",showTitle)
    gsub(/&amp;/,"\\&",showTitle)
    gsub(/&quot;/,"\"\"",showTitle)
    gsub(/&#039;/,"'",showTitle)
    gsub(/&euml;/,"ë",showTitle)
    print showTitle >> RAW_TITLES
    # print "==> showTitle = " showTitle > "/dev/stderr"
    next
}

# Extract the show URL
/meta property="og:url/ {
    split($0,fld,"\"")
    showURL = fld[4]
    # print "==> showURL = " showURL > "/dev/stderr"
    # Create shorter URL by removing https://
    shortURL = showURL
    sub(/.*acorn\.tv/,"acorn.tv",shortURL)
    next
}

# Extract the number of episodes in the show
/itemprop="numberOfEpisodes"/ {
    episodeLinesFound += 1
    split($0,fld,"\"")
    if (episodeLinesFound == 1) {
        # Make seasonEpisodes a spreadsheet formula
        seasonEpisodes = "="
        showEpisodes = fld[4]
        if (showEpisodes == "") {
            printf("==> Blank showEpisodes in numberOfEpisodes: %s\t%s\n", shortURL,
                    showTitle) >> ERRORS
        }
        # print "==> showEpisodes = " showEpisodes " " shortURL > "/dev/stderr"
    }
    if (episodeLinesFound != 1) {
        seasonEpisodes = seasonEpisodes "+" fld[4]
        if (seasonEpisodes == "") {
            printf("==> Blank seasonEpisodes in numberOfEpisodes: %s\t%s\n", shortURL,
                    showTitle) >> ERRORS
        }
        # print "==> seasonEpisodes = " seasonEpisodes " " shortURL > "/dev/stderr"
    }
    next
}

# Extract the number of seasons in the show
/itemprop="numberOfSeasons"/ {
    seasonLinesFound += 1
    split($0,fld,"\"")
    showSeasons = fld[4]
    totalSeasons += showSeasons
    # Default showType to "S" for Season
    showType = "S"
    if (showSeasons == "") {
        printf("==> Blank showSeasons in numberOfSeasons: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    # print "==> showSeasons = " showSeasons " " shortURL > "/dev/stderr"
    next
}

# Extract the show description
/id="franchise-description"/ {
    descriptionLinesFound += 1
    getline showDescription
    # fix sloppy input spacing
    gsub(/\t/,"",showDescription)
    sub(/<.*$/,"",showDescription)
    gsub(/ \./,".",showDescription)
    gsub(/  */," ",showDescription)
    sub(/^ */,"",showDescription)
    sub(/ *$/,"",showDescription)
    # fix funky HTML characters
    gsub(/&amp;/,"\\&",showDescription)
    gsub(/&quot;/,"\"",showDescription)
    gsub(/&#039;/,"'",showDescription)
    # fix unmatched quotes
    numQuotes = gsub(/"/,"\"",showDescription)
    if ((numQuotes % 2) == 1) {
        printf("==> Changed unmatched quote (%d): %d\t%s\t%s\t%s\n", numQuotes, shortURL,
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
    split($0,fld,"\"")
    seasonNumber = fld[4]
    # print "==> seasonNumber = " seasonNumber " " shortURL > "/dev/stderr"
    next
}

# Extract the episode URL
/<a itemprop="url"/ {
    totalEpisodes += 1
    split($0,fld,"\"")
    episodeURL = fld[4]
    sub(/\/$/,"",episodeURL)
    # print "==> episodeURL = " episodeURL > "/dev/stderr"
    print episodeURL >> EPISODE_URLS
    shortEpisodeURL = episodeURL
    sub(/.*acorn\.tv/,"acorn.tv",shortEpisodeURL)
    split(episodeURL, part, "/")
    shortSeasonURL = "acorn.tv/" part[4] "/" part[5]
    # If episode is a Jack Irish movie, set showType to "M"
    if (episodeURL ~ /\/jackirish\/themovies\//) {
        showType = "M"
        printf("==> Changed showType to movie '%s': %s\n", showTitle, shortEpisodeURL) >> ERRORS
    }
    # but don't make the series a movie
    if (episodeURL ~ /\/jackirish\/series/) {
        showType = "S"
    }
    # extract the episode description
    cmd = "curl -s " episodeURL " | grep '<meta itemprop=\"description\"' | head -1"
    while ((cmd | getline desc ) > 0) {
        split(desc,fld,"\"")
        episodeDescription = fld[4]
        # fix sloppy input spacing
        gsub(/ \./,".",episodeDescription)
        gsub(/  */," ",episodeDescription)
        sub(/^ */,"",episodeDescription)
        sub(/ *$/,"",episodeDescription)
        # fix funky HTML characters
        gsub(/&amp;/,"\\&",episodeDescription)
        gsub(/&quot;/,"\"\"",episodeDescription)
        gsub(/&#039;/,"'",episodeDescription)
    }
    close (cmd)
    # Get episodeNumber which is no longer available from showURL
    cmd = "curl -s " episodeURL " | grep '<meta itemprop=\"episodeNumber\"'"
    while ((cmd | getline epNum ) > 0) {
        # print "==> epNum = " epNum > "/dev/stderr"
        split(epNum,fld,"\"")
        episodeNumber = fld[4]
    }
    # print "==> episodeNumber = " episodeNumber > "/dev/stderr"
    close (cmd)
    next
}

# Set showType to "M" for Movies
/<h6> Movie/ {
    # Detectorists has a movie as its last season/episode
    if (showURL ~ /\/detectorists$/)
        next
    totalMovies += 1
    showType = "M"
    # Movies don't usually have seasons or episodes, but some do
    # Don't make the movie a season by itself - bonus features should belong to the same "season"
    showSeasons > 1 ? showSeasons -= 1 : showSeasons = ""
    # Subtract the movie itself from the number of episodes
    showEpisodes > 1 ? showEpisodes -= 1 : showEpisodes = ""
    showEpisodes > 1 ? seasonEpisodes = "=" : seasonEpisodes =""
    # print "==> showSeasons = " showSeasons " " shortURL > "/dev/stderr"
    # print "==> showEpisodes = " showEpisodes " " shortURL > "/dev/stderr"
    # print "==> seasonEpisodes = " seasonEpisodes " " shortURL > "/dev/stderr"
    # print "---" > "/dev/stderr"
}

# Set showType to "P" for Prequel episodes so they sort before any Season episodes
/<h6>Prequel Movies: / {
    showType = "P"
    # printf("==> Prequel to '%s': %s\n", showTitle, shortEpisodeURL) >> ERRORS
}

# Extract the episode duration
/<meta itemprop="timeRequired"/ {
    durationLinesFound += 1
    split($0,fld,"\"")
    split(fld[4],tm,/[TMS]/)
    secs = tm[3]
    mins = tm[2] + int(secs / 60)
    hrs =  int(mins / 60)
    secs %= 60; mins %= 60
    #
    if (showURL !~ /_cs$/) {
        totalTime[3] += secs
        totalTime[2] += mins + int(totalTime[3] / 60)
        totalTime[1] += hrs + int(totalTime[2] / 60)
        totalTime[3] %= 60; totalTime[2] %= 60
    }
    #
    showSecs += secs
    showMins += mins + int(showSecs / 60)
    showHrs += hrs + int(showMins / 60)
    showSecs %= 60; showMins %= 60
    #
    episodeDuration = sprintf("%02d:%02d:%02d", hrs, mins, secs)
    # Save the first duration to deal with movies with bonus episodes
    if (durationLinesFound == 1)
        firstDuration = episodeDuration
    # print "==> episodeDuration = " episodeDuration " " shortEpisodeURL > "/dev/stderr"
    if (episodeDuration == "00:00:00")
        printf("==> Blank episode duration: %s  %s\n", shortEpisodeURL, showTitle) >> ERRORS
    next
}

# Extract the episode title
/<h5 itemprop="name">/ {
    split($0,fld,"[<>]")
    episodeTitle = fld[3]
    gsub(/&amp;/,"\\&", episodeTitle)
    gsub(/&#039;/,"'",episodeTitle)
    # print "==> episodeTitle = " episodeTitle " " shortEpisodeURL > "/dev/stderr"
    # print "==> episodeNumber = " episodeNumber " " shortEpisodeURL > "/dev/stderr"
    # 
    # Setup episodeType so episodes group/sort properly
    # Default episodeType to "E"
    episodeType = "E"
    # Default bonus and christmas specials episodeType to "X"
    if (episodeURL ~ /\/bonus|bonus\/|christmas[-]?special/) {
        episodeType = "X"
        # printf("==> Bonus to '%s': %s\n", showTitle, shortEpisodeURL) > "/dev/stderr"
    }
    # If episode is a Trailer, set episodeType to "T" - even though not all these have episodes
    if (episodeURL ~ /_cs\/|\/trailer$/) {
        episodeType = "T"
        # printf("==> Trailer '%s': %s\n", showTitle, shortEpisodeURL) >> ERRORS
    }
    #
    # cryptoftears, newworlds & newtonslaw bonus seasonNumber should be 1
    if (episodeURL ~ \
        /\/cryptoftears\/bonus\/|\/newworlds\/bonus\/|\/newtonslaw\/bonus\// \
        && seasonNumber != 1) {
            printf("==> Changed S%02d to S01: %s\n", seasonNumber, shortSeasonURL) >> ERRORS
        seasonNumber = 1
    }
    # Plain christmasspecial, seriesfinale don't increment seasonNumber
    if (episodeURL ~ /\/christmasspecial\/|\/seriesfinale\//) {
        printf("==> Changed S%02d to S%02d: %s\n", seasonNumber, seasonNumber-1, 
                shortSeasonURL) >> ERRORS
        seasonNumber -= 1
    }
    #
    # The season number should match that in the URL
    # Birds of a Feather, Doc Martin, Murdoch, Poirot, Rebus, Vera, and others have problems
    if (episodeURL ~ \
           /\/series[0-9]+\/|[0-9]+bonus\/|\/murdoch\/season[0-9]+/) {
        split(episodeURL, part, "/")
        URLseasonNumber = part[5]
        sub(/bonus/,"",URLseasonNumber)
        # Foyle's War has sets: foyleswar/series9set8bonus/
        sub(/set[0-9]/,"",URLseasonNumber)
        # Midsomer Murders has two parts: midsomermurders/series19parttwo/
        sub(/parttwo/,"",URLseasonNumber)
        sub(/christmasspecial/,"",URLseasonNumber)
        sub(/[[:alpha:]]*/,"",URLseasonNumber)
        if (URLseasonNumber != seasonNumber) {
            printf("==> Changed S%02d to S%02d: %s\n", seasonNumber, URLseasonNumber,
                    shortSeasonURL) >> ERRORS
            seasonNumber = URLseasonNumber
        }
    }
    #
    # Wrap up this episode
    # =HYPERLINK("https://acorn.tv/1900island/series1/week-one";"1900 Island, S01E01, Week One")
    episodeLink = sprintf("=HYPERLINK(\"%s\";\"%s, %s%02d%s%02d, %s\")", episodeURL, showTitle,
                    showType, seasonNumber, episodeType, episodeNumber, episodeTitle)
    # Print "episode" line to UNSORTED
    # But don't include duration for trailers
    if (episodeType == "T")
        episodeDuration = ""
    # =HYPERLINK("https://acorn.tv/1900island/series1/week-one";"1900 Island, S01E01, Week One") \
    # \t\t\t 00:59:17 \t As they arrive
    printf("%s\t\t\t%s\t%s\n", episodeLink, episodeDuration, episodeDescription)
    # Make sure there is no carryover
    episodeURL = ""
    shortEpisodeURL = ""
    shortSeasonURL = ""
    episodeType = ""
    episodeTitle = ""
    episodeNumber = ""
    episodeDuration = ""
    # Default showType to "S" for Season so it can change from Prequel to Season unless it's a Movie
    if (showType != "M")
        showType = "S"
    # 
    next
}

# Wrap up this show
/<footer/ {
    if (episodeLinesFound == 0) {
        printf("==> No numberOfEpisodes: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (seasonLinesFound == 0) {
        printf("==> No numberOfSeasons: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (descriptionLinesFound == 0) {
        printf("==> No franchise-description: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    if (durationLinesFound == 0) {
        printf("==> No durations: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    showDuration = sprintf("%02d:%02d:%02d", showHrs, showMins, showSecs)
    showDurationText = sprintf("%02dh %02dm", showHrs, showMins)
    # If it's not a trailer
    if (showURL !~ /_cs$/) {
        # Print "show" line to SHORT_SPREADSHEET with showDurationText
        printf("%s\t%s\t%s\t%s\t%s\n", showLink, showSeasons, seasonEpisodes, showDurationText, \
                showDescription) >> SHORT_SPREADSHEET
        # Print "show" line to UNSORTED without showDuration except movies & single episode shows
        if (showSeasons == 1 && showEpisodes == 1) {
            printf("==> Only one episode: %s '%s'\n", shortURL, showTitle) >> ERRORS
            showDuration = ""
        }
        if (showType != "M") {
            showDuration = ""
        }
        # print  "==> showTitle = " showTitle > "/dev/stderr"
        # print  "==> showType = " showType > "/dev/stderr"
        # print  "==> showEpisodes = " showEpisodes > "/dev/stderr"
        # print "---" > "/dev/stderr"
        if (showType == "M" && showEpisodes != "") {
            showDuration = firstDuration
            printf("==> Movie '%s' has %d bonus episodes: %s\n", showTitle, showEpisodes,
                    shortURL) >> ERRORS
        }
        printf("%s\t%s\t%s\t%s\t%s\n", showLink, showSeasons, seasonEpisodes,  showDuration, \
                showDescription)
    }
    # Make sure there is no carryover
    showTitle = ""
    showType = ""
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
    durationLinesFound = 0
}

END {
    printf("%02dh %02dm\n", totalTime[1], totalTime[2]) >> DURATION

    printf("In getAcornFrom-showPages.awk\n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1 ? pluralEpisodes = "episode" : pluralEpisodes = "episodes"
    #
    printf("    Processed %d %s, %d %s, %d %s, %d %s\n", totalMovies, pluralMovies, totalShows,
            pluralShows, totalSeasons, pluralSeasons, totalEpisodes, pluralEpisodes) > "/dev/stderr"
}
