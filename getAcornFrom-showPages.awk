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

# Generic functions
function clearShowVariables() {
    showTitle = ""
    showType = "S"
    showURL = ""
    shortURL = ""
    showLink = ""
    seasonTitle = ""
    seasonNumber = ""
    showSeasons = ""
    showEpisodes = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    showDuration = ""
    showDescription = ""
    #
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound = 0
    durationLinesFound = 0
}

function clearEpisodeVariables() {
    showType = "S"
    episodeURL = ""
    shortEpisodeURL = ""
    episodeType = "E"
    episodeTitle = ""
    episodeNumber = ""
    episodeDuration = ""
}

function fixUnicode() {
    gsub(/\\u00a0/, " ", showDescription)
    gsub(/\\u00ae/, "®", showDescription)
    gsub(/\\u00e1/, "á", showDescription)
    gsub(/\\u00e4/, "ä", showDescription)
    gsub(/\\u00e7/, "ç", showDescription)
    gsub(/\\u00e8/, "è", showDescription)
    gsub(/\\u00e9/, "é", showDescription)
    gsub(/\\u00eb/, "ë", showDescription)
    gsub(/\\u00ed/, "í", showDescription)
    gsub(/\\u00f6/, "ö", showDescription)
    gsub(/\\u01a0/, "Ơ", showDescription)
}

function fixSeasonNumber() {
    split(episodeURL, part, "/")
    URLseasonNumber = part[5]
    sub(/bonus$/, "", URLseasonNumber)
    sub(/christmasspecial$/, "", URLseasonNumber)
    sub(/aftershow$/, "", URLseasonNumber)

    # The season number should match the one in the URL
    # Doc Martin, Murdoch, and others have problems
    if (match(URLseasonNumber, /[[:digit:]]{1,2}$/)) {
        # print "==> URLseasonString = " URLseasonNumber > "/dev/stderr"
        URLseasonNumber = substr(URLseasonNumber, RSTART)
        # print "==> episodeURL = " episodeURL > "/dev/stderr"
        # print "==> seasonTitle = " seasonTitle " " shortURL > "/dev/stderr"
        # print "==> seasonNumber = " seasonNumber > "/dev/stderr"
        # print "==> URLseasonNumber = " URLseasonNumber "\n" > "/dev/stderr"
        if (URLseasonNumber != seasonNumber) {
            printf(\
                "==> Changed S%02d to S%02d: %s\n",
                seasonNumber,
                URLseasonNumber,
                shortEpisodeURL\
            ) >> ERRORS
            seasonNumber = URLseasonNumber
        }
    }

    # cryptoftears is all one season
    if (episodeURL ~ /\/cryptoftears\//) { seasonNumber = 1 }
}

function getDataFromEpisode() {
    # extract the episode description
    cmd = "curl -s " episodeURL\
        " | rg -m 3 '^ {8}<meta itemprop=\"description\"|^ {8}<meta itemprop=\"episodeNumber\"|^ {8}<meta itemprop=\"timeRequired\"'"

    while ((cmd | getline episodeData) > 0) {
        if (episodeData ~ /itemprop="description"/) {
            split(episodeData, fld, "\"")
            episodeDescription = fld[4]
            # fix sloppy input spacing
            gsub(/ \./, ".", episodeDescription)
            gsub(/  */, " ", episodeDescription)
            sub(/^ */, "", episodeDescription)
            sub(/ *$/, "", episodeDescription)
            # fix funky HTML characters
            gsub(/&amp;/, "\\&", episodeDescription)
            gsub(/&quot;/, "\"\"", episodeDescription)
            gsub(/&#039;/, "'", episodeDescription)
            # print "==> episodeDescription = " episodeDescription > "/dev/stderr"
        }

        if (episodeData ~ /itemprop="episodeNumber"/) {
            # Get episodeNumber which is no longer available from showURL
            split(episodeData, fld, "\"")
            episodeNumber = fld[4]
            # print "==> episodeNumber = " episodeNumber > "/dev/stderr"
        }

        if (episodeURL ~ /\/thegreattrainrobbery\/trailer/) {
            episodeNumber = 3
        }

        if (episodeData ~ /itemprop="timeRequired"/) {
            # Get duration which is no longer available from showURL
            durationLinesFound += 1
            split(episodeData, fld, "\"")
            split(fld[4], tm, /[TMS]/)
            secs = tm[3]
            mins = tm[2] + int(secs / 60)
            hrs = int(mins / 60)
            secs %= 60
            mins %= 60
            #
            totalTime[3] += secs
            totalTime[2] += mins + int(totalTime[3] / 60)
            totalTime[1] += hrs + int(totalTime[2] / 60)
            totalTime[3] %= 60
            totalTime[2] %= 60

            #
            showSecs += secs
            showMins += mins + int(showSecs / 60)
            showHrs += hrs + int(showMins / 60)
            showSecs %= 60
            showMins %= 60
            #
            episodeDuration = sprintf("%02d:%02d:%02d", hrs, mins, secs)

            # print "==> episodeDuration = " episodeDuration " " shortEpisodeURL "\n" > "/dev/stderr"
            if (episodeDuration == "00:00:00")
                printf(\
                    "==> Blank episode duration: %s  %s\n",
                    shortEpisodeURL,
                    showTitle\
                ) >> ERRORS
        }
    }

    close(cmd)
}

function wrapUpEpisode() {
    # Report invalid episodeNumber
    if (episodeNumber + 0 == 0) {
        printf(\
            "==> Zero episodeNumber in \"%s: %s\" %s\n",
            showTitle,
            episodeTitle,
            shortEpisodeURL\
        ) >> ERRORS
    }

    # =HYPERLINK("https://acorn.tv/1900island/series1/week-one";"1900 Island, S01E01, Week One")
    episodeLink = sprintf(\
        "=HYPERLINK(\"%s\";\"%s, %s%02d%s%02d, %s\")",
        episodeURL,
        showTitle,
        showType,
        seasonNumber,
        episodeType,
        episodeNumber,
        episodeTitle\
    )
    # Print "episode" line to UNSORTED
    # =HYPERLINK("https://acorn.tv/1900island/series1/week-one";"1900 Island, S01E01, Week One") \
    # \t\t\t 00:59:17 \t As they arrive
    printf("%s\t\t\t%s\t%s\n", episodeLink, episodeDuration, episodeDescription)
}

# Extract the show URL, title, and description
/<script type="application\/ld\+json">/, /"description": "/ {
    # Extract the show URL
    if ($0 ~ /^ {8}"url": "/) {
        clearShowVariables()

        totalShows += 1
        split($0, fld, "\"")
        showURL = fld[4]
        gsub(/\\/, "", showURL)
        # print "==> showURL = " showURL > "/dev/stderr"
        # Create shorter URL by removing https://
        shortURL = showURL
        sub(/.*acorn\.tv/, "acorn.tv", shortURL)
        next
    }

    # Extract the show title
    if ($0 ~ /^ {8}"name": "/) {
        split($0, fld, "\"")
        showTitle = fld[4]
        # print "==> showTitle = " showTitle > "/dev/stderr"
        print showTitle >> RAW_TITLES
        next
    }

    # Extract the show description
    if ($0 ~ /^ {8}"description": "/) {
        descriptionLinesFound += 1
        showDescription = $0
        sub(/.*"description": "/, "", showDescription)
        sub(/",$/, "", showDescription)
        sub(/"$/, "", showDescription)

        # fix sloppy input spacing
        # sub(/<.*$/, "", showDescription)
        sub(/^ */, "", showDescription)
        sub(/ *$/, "", showDescription)
        # gsub(/\t/, "", showDescription)
        gsub(/ \./, ".", showDescription)
        gsub(/  */, " ", showDescription)

        # fix funky HTML characters
        fixUnicode()

        # print "==> " shortURL " description = " showDescription > "/dev/stderr"
        next
    }
}

# Determine the number of seasons in the show
/^ {12}<h4 class="subnav2">/ {
    split($0, fld, "[<>]")
    seasonTitle = fld[3]
    seasonNumber += 1
    # print "\n==> seasonTitle = " shortURL " " seasonTitle > "/dev/stderr"
    # print "==> seasonNumber = " shortURL " " seasonNumber > "/dev/stderr"

    seasonLinesFound += 1
    showSeasons += 1
    totalSeasons += 1
    # print "\n==> seasonNumber = " seasonNumber " " shortURL > "/dev/stderr"
    # print "==> seasonTitle = " seasonTitle " " shortURL > "/dev/stderr"
    next
}

# Deal with <a href
/^ {16}<a href="https:\/\/acorn.tv\// {
    # print $0 > "/dev/stderr"
    sub(/<a/, " ", $0)
}

# Extract the episode URL
/^ {18}href="https:\/\/acorn.tv\// {
    clearEpisodeVariables()

    episodeLinesFound += 1
    showEpisodes += 1
    # print "==> showEpisodes = " showEpisodes " " shortURL > "/dev/stderr"
    numberOfEpisodes += 1
    # print "==> numberOfEpisodes = " numberOfEpisodes " " shortURL > "/dev/stderr"
    totalEpisodes += 1

    split($0, fld, "\"")
    episodeURL = fld[2]
    sub(/\/$/, "", episodeURL)
    # print "==> episodeURL = " episodeURL > "/dev/stderr"
    print episodeURL >> EPISODE_URLS

    shortEpisodeURL = episodeURL
    sub(/.*acorn\.tv/, "acorn.tv", shortEpisodeURL)

    # May need to fix the season number using the episodeURL
    fixSeasonNumber()

    # If episode is a Doc Martin Prequel, set showType to "P"
    if (episodeURL ~ /\/docmartin\/prequelmovies\//) {
        showType = "P"
        printf(\
            "==> Changed showType to prequel '%s': %s\n",
            showTitle,
            shortEpisodeURL\
        ) >> ERRORS
    }

    # If episode is a Jack Irish movie, set showType to "M"
    if (episodeURL ~ /\/jackirish\/themovies\//) {
        showType = "M"
        printf(\
            "==> Changed showType to movie '%s': %s\n",
            showTitle,
            shortEpisodeURL\
        ) >> ERRORS
    }

    # but don't make the series a movie
    if (episodeURL ~ /\/jackirish\/series/) { showType = "S" }

    if (episodeURL ~ /\/bonus|bonus-\/|christmas[-]?special/) {
        episodeType = "X"
    }

    split(episodeURL, part, "/")
    shortEpisodeURL = "acorn.tv/" part[4] "/" part[5]

    getDataFromEpisode()

    next
}

# Extract the episode title
/^ {20}<h5>/ {
    split($0, fld, "[<>]")
    episodeTitle = fld[3]
    # print "==> episodeTitle = '" episodeTitle "' " shortEpisodeURL > "/dev/stderr"
    if ($0 !~ /<\/h5>/) {
        getline possibleTitle

        while (possibleTitle !~ /<\/h5>/) {
            sub(/^ */, "", possibleTitle)
            # print "==> possibleTitle = " possibleTitle > "/dev/stderr"
            episodeTitle = episodeTitle " " possibleTitle
            # print "==> episodeTitle = " episodeTitle > "/dev/stderr"
            getline possibleTitle
        }
    }

    sub(/^ */, "", episodeTitle)
    gsub(/&amp;/, "\\&", episodeTitle)
    gsub(/&#039;/, "'", episodeTitle)
    wrapUpEpisode()
    next
}

# Set showType to "M" for Movies
/<h6>Movie/ {
    totalMovies += 1
    showType = "M"

    # Detectorists has a movie as its last season/episode
    if (showURL ~ /\/detectorists$/) next

    # Movies don't usually have seasons or episodes, but some do
    # Don't make the movie a season by itself - bonus features should belong to the same "season"
    showSeasons > 1 ? showSeasons -= 1 : showSeasons = ""
    # Subtract the movie itself from the number of episodes
    showEpisodes > 1 ? showEpisodes -= 1 : showEpisodes = ""
    # print "==> showSeasons = " showSeasons " " shortURL > "/dev/stderr"
    # print "==> showEpisodes = " showEpisodes " " shortURL > "/dev/stderr"
    # print "---" > "/dev/stderr"
}

# Wrap up this show
/<footer/ {
    if (episodeLinesFound == 0) {
        printf(\
            "==> No numberOfEpisodes: %s\t%s\n", shortURL, showTitle\
        ) >> ERRORS
    }

    if (seasonLinesFound == 0) {
        printf(\
            "==> No numberOfSeasons: %s\t%s\n", shortURL, showTitle\
        ) >> ERRORS
    }

    if (descriptionLinesFound == 0) {
        printf(\
            "==> No franchise-description: %s\t%s\n", shortURL, showTitle\
        ) >> ERRORS
    }

    if (durationLinesFound == 0) {
        printf("==> No durations: %s\t%s\n", shortURL, showTitle) >> ERRORS
    }

    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    showDuration = sprintf("%02d:%02d:%02d", showHrs, showMins, showSecs)
    showDurationText = sprintf("%02dh %02dm", showHrs, showMins)
    # Print "show" line to SHORT_SPREADSHEET with showDurationText
    printf(\
        "%s\t%s\t%s\t%s\t%s\n",
        showLink,
        showSeasons,
        showEpisodes,
        showDurationText,
        showDescription\
    ) >> SHORT_SPREADSHEET
    # Print "show" line to UNSORTED without showDuration except movies & single episode shows
    if (showSeasons == 1 && showEpisodes == 1) {
        printf("==> Only one episode: %s '%s'\n", shortURL, showTitle) >> ERRORS
        showDuration = ""
    }

    if (showType != "M") { showDuration = "" }

    # print  "==> showTitle = " showTitle > "/dev/stderr"
    # print  "==> showType = " showType > "/dev/stderr"
    # print  "==> showEpisodes = " showEpisodes > "/dev/stderr"
    # print "---" > "/dev/stderr"
    if (showType == "M" && showEpisodes != "") {
        printf(\
            "==> Movie '%s' has %d bonus episodes: %s\n",
            showTitle,
            showEpisodes,
            shortURL\
        ) >> ERRORS
    }

    printf(\
        "%s\t%s\t%s\t%s\t%s\n",
        showLink,
        showSeasons,
        showEpisodes,
        showDuration,
        showDescription\
    )
}

END {
    printf("%02dh %02dm\n", totalTime[1], totalTime[2]) >> DURATION

    printf("In getAcornFrom-showPages.awk\n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    #
    printf(\
        "    Processed %d %s, %d %s, %d %s, %d %s\n",
        totalMovies,
        pluralMovies,
        totalShows,
        pluralShows,
        totalSeasons,
        pluralSeasons,
        totalEpisodes,
        pluralEpisodes\
    ) > "/dev/stderr"
}
