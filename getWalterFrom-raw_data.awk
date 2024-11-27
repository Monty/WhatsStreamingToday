# Grab fields from Walter Presents HTML files
#
# Title  Seasons  Episodes  Duration  Genre  Language  Rating  Description
/^https:/ {
    totalShows += 1
    split($0, fld, "\t")
    showURL = fld[1]
    # print "==> showURL = " showURL > "/dev/stderr"
    # Create shorter URL by removing https://
    shortURL = showURL
    sub(/.*pbs.org/, "pbs.org", shortURL)
    showTitle = fld[2]

    if (shortURL ~ /before-we-die-uk/) { showTitle = "Before We Die (UK)" }

    print showTitle >> RAW_TITLES
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    # print "==> showLink = " showLink > "/dev/stderr"
    showLanguage = "English"
    next
}

/ with English subtitles/ {
    split($0, fld, " ")
    showLanguage = $(NF - 3)
    # print "==> showLanguage = " showLanguage > "/dev/stderr"
}

/"description": "/ {
    descriptionLinesFound++
    split($0, fld, "\"")
    showDescription = fld[4]
    gsub(/&#x27;/, "'", showDescription)
    gsub(/&quot;/, "\"", showDescription)
    sub(/ with English subtitles/, "", showDescription)
    sub(/ From Walter Presents, in/, " In", showDescription)
    # print "==> showDescription = " showDescription > "/dev/stderr"
    next
}

/"genre": "/ {
    genreLinesFound++
    split($0, fld, "\"")
    showGenre = fld[4]
    next
}

/"numberOfSeasons": / {
    sub(/.*"numberOfSeasons": /, "")
    split($0, fld, ",")
    showSeasons = fld[1] - 1
    # print "==> showSeasons = " showSeasons > "/dev/stderr"
    getline seasonNumber
    split(seasonNumber, fld, "\"")
    seasonNumber = fld[8]
    sub(/Season /, "", seasonNumber)
    # print "==> seasonNumber = " seasonNumber > "/dev/stderr"
    next
}

# Episode processing: Titles
/class="VideoDetailThumbnail_video_title/ {
    episodeType = "E"
    testTitle = ""
    getline
    getline
    getline
    getline
    # href="/video/episode-2-kFUiL6/"
    split($0, fld, "\"")
    episodeID = sprintf("%s", fld[2])
    episodeURL = sprintf("https://www.pbs.org%s", episodeID)
    # print "==> episodeURL = " episodeURL > "/dev/stderr"
    getline
    sub(/^ */, "")

    if ($0 !~ /^>/) {
        printf("==> Missing ^< in testTitle line: '%s'\n", $0) >> ERRORS
    }

    split($0, fld, "[<>]")
    testTitle = fld[2]

    # Title can be one or more lines
    # >Brevard County</a
    # >Central Florida Roadtrip: Black History in Central
    # Florida</a
    if (testTitle !~ /<\/a/) {
        getline
        sub(/^ */, "")
        split($0, fld, "[<>]")
        testTitle = testTitle " " fld[1]
    }

    # print "==> testTitle = " testTitle > "/dev/stderr"
    split(testTitle, fld, "[<>]")
    episodeTitle = fld[1]
    sub(/&amp;/, "\\&", episodeTitle)
    # print "==> " showTitle ":" episodeTitle > "/dev/stderr"
}

# Don't process lines containing only a ">"
/^ *>$/ { next }

# Episode processing: Descriptions
/class="VideoDetailThumbnail_video_description/ {
    getline

    while ($0 !~ /<\/p>/) {
        sub(/^ */, "")
        episodeDescription = episodeDescription $0 " "
        getline
    }

    # Clean up episodeDescription
    sub(/^> /, "", episodeDescription)
    sub(/ $/, "", episodeDescription)
    sub(/&amp;/, "\\&", episodeDescription)
    gsub(/&#x27;/, "'", episodeDescription)
    gsub(/&quot;/, "\"", episodeDescription)

    if (episodeDescription ~ /\(.*[0-9][hms]\)$/) {
        if ((match(episodeDescription, / \([0-9]{1,2}.*[hms]\)$/)) > 0) {
            episodeHMS = substr(episodeDescription, RSTART + 2, RLENGTH - 3)
            episodeDescription = substr(episodeDescription, 1, RSTART - 1)
            # print "episodeHMS = " episodeHMS > "/dev/stderr"
            durationLinesFound++
        }
    }

    if (episodeDescription ~ /^Ep[0-9]* \| /) {
        # Shows with only one season (which may not be season 1)
        # "Ep4 | Sharko travels ... with Syndrome E. (54m 37s) "
        split($0, fld, " ")
        episodeNumber = fld[1]
        sub(/Ep/, "", episodeNumber)
        episodeLinesFound++
        totalEpisodes++
        split(episodeDescription, fld, "|")
        episodeDescription = fld[2]
        sub(/^ /, "", episodeDescription)
    }
    else if (episodeDescription ~ /^ *S.[0-9]* Ep[0-9]* \| /) {
        # Shows with more then one season
        # "S2 Ep3 | The Circle’s ... life on the line. (58m 34s) "
        split($0, fld, " ")
        episodeNumber = fld[2]
        sub(/Ep/, "", episodeNumber)
        episodeLinesFound++
        totalEpisodes++
        split(episodeDescription, fld, "|")
        episodeDescription = fld[2]
        sub(/^ /, "", episodeDescription)
    }
    else {
        # Specials have description immediately following key
        # <p class="VideoDetailThumbnail_video_description__ZSGKS">
        # Dr. Cartwright discusses ... the future of UCF. (48m 2s)
        # "A woman is murdered. Can ... find it? (1h 31m 34s) "
        episodeType = "X"
        specialEpisodeNumber++
        episodeLinesFound++
        totalEpisodes++
    }

    # May be able to filter by time, i.e. less than 5 minutes
    # "Clip | Goran has questions ... father's disappearance. (1m 18s) "
    # Don't save Previews, e.g. "Season 2 Preview"
    # print "\"" episodeDescription "\"" > "/dev/stderr"
    # print "episodeLinesFound = " episodeLinesFound > "/dev/stderr"
    # print "" > "/dev/stderr"

    # Wrap up episode
    # Leading spaces have been deleted in episode logic
    /^S.[0-9]* Ep[0-9]* \| / || /^Ep[0-9]* \| / ||
    /^                                    Special \| / ||
    /^[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| /
    {
        numFields = split(episodeHMS, tm, " ")
        # Initialize fields to 0 in case any are missing
        secs = mins = hrs = 0

        for (i = 1; i <= numFields; ++i) {
            if (tm[i] ~ /s/) {
                sub(/s/, "", tm[i])
                secs = tm[i]
            }

            if (tm[i] ~ /m/) {
                sub(/m/, "", tm[i])
                mins = tm[i]
            }

            if (tm[i] ~ /h/) {
                sub(/h/, "", tm[i])
                hrs = tm[i]
            }
        }

        showSecs += secs
        showMins += mins + int(showSecs / 60)
        showHrs += hrs + int(showMins / 60)
        showSecs %= 60
        showMins %= 60

        totalTime[3] += secs
        totalTime[2] += mins + int(totalTime[3] / 60)
        totalTime[1] += hrs + int(totalTime[2] / 60)
        totalTime[3] %= 60
        totalTime[2] %= 60

        episodeDuration = sprintf("%02d:%02d:%02d", hrs, mins, secs)

        if (episodeType == "X") episodeNumber = specialEpisodeNumber

        # Special case for Central Florida Roadtrip season 2
        if (episodeNumber + 0 >= 18000) episodeNumber = episodeNumber - 18000

        # Special case for episodeNumbers that include season number
        if (episodeNumber + 0 >= 100)
            episodeNumber = episodeNumber - seasonNumber * 100

        episodeLink = sprintf(\
            "=HYPERLINK(\"%s\";\"%s, S%02d%s%02d, %s\")",
            episodeURL,
            showTitle,
            seasonNumber,
            episodeType,
            episodeNumber,
            episodeTitle\
        )
        printf(\
            "%s\t\t\t%s\t\t\t\t%s\n",
            episodeLink,
            episodeDuration,
            episodeDescription\
        ) >> LONG_SPREADSHEET
        printf("%s\t%s\n", episodeID, showTitle) >> EPISODE_IDS

        episodeTitle = ""
        episodeType = ""
        episodeURL = ""
        episodeDuration = ""
        episodeLink = ""
        episodeDescription = ""
        next
    }
}

/Copyright ©/ {
    # print showTitle > "/dev/stderr"
    if (episodeLinesFound == 0) {
        printf(\
            "==> No episodes found: %s '%s'\n", shortURL, showTitle\
        ) >> ERRORS
    }

    if (episodeLinesFound == 1) {
        printf("==> Only one episode: %s '%s'\n", shortURL, showTitle) >> ERRORS
    }

    if (descriptionLinesFound == 0) {
        printf(\
            "==> No description found: %s '%s'\n", shortURL, showTitle\
        ) >> ERRORS
    }

    if (genreLinesFound == 0) {
        printf("==> No genre found: %s '%s'\n", shortURL, showTitle) >> ERRORS
    }

    if (durationLinesFound == 0) {
        printf(\
            "==> No durations found: %s '%s'\n", shortURL, showTitle\
        ) >> ERRORS
    }

    # Fix any known issues
    if (showTitle == "La Otra Mirada" && showLanguage != "Spanish") {
        printf("==> Setting '%s' language to Spanish\n", showTitle) >> ERRORS
        showLanguage = "Spanish"
    }

    if (showTitle == "Superabundant" && showGenre == "") {
        printf("==> Setting '%s' genre to Food\n", showTitle) >> ERRORS
        showGenre = "Food"
    }

    # Wrap up show
    showDurationText = sprintf("%02dh %02dm", showHrs, showMins)
    totalSeasons += showSeasons

    if (showSeasons == 0) {
        printf("==> No seasons found: %s '%s'\n", shortURL, showTitle) >> ERRORS
    }
    else {
        printf(\
            "%s\t%s\t%s\t%s\t%s\t%s\t\t%s\n",
            showLink,
            showSeasons,
            episodeLinesFound,
            showDurationText,
            showGenre,
            showLanguage,
            showDescription\
        )
        printf(\
            "%s\t%s\t%s\t\t%s\t%s\t\t%s\n",
            showLink,
            showSeasons,
            episodeLinesFound,
            showGenre,
            showLanguage,
            showDescription\
        ) >> LONG_SPREADSHEET
    }

    # Make sure there is no carryover
    showURL = ""
    showTitle = ""
    showLink = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    showSeasons = 0
    showDuration = ""
    showDescription = ""
    showGenre = ""
    showLanguage = ""
    delete seasonsArray
    delete episodeArray
    #
    episodeNumber = 0
    specialEpisodeNumber = 0
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound = 0
    genreLinesFound = 0
    durationLinesFound = 0
}

END {
    printf("%02dh %02dm\n", totalTime[1], totalTime[2]) > DURATION
    printf("In getWalterFrom-raw_data.awk\n") > "/dev/stderr"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    printf(\
        "    Processed %d %s, %d %s, %d %s\n",
        totalShows,
        pluralShows,
        totalSeasons,
        pluralSeasons,
        totalEpisodes,
        pluralEpisodes\
    ) > "/dev/stderr"
}
