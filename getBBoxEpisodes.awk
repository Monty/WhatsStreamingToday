# Produce an episode spreadsheet from TV Episodes html

# INVOCATION:
# awk -v ERRORS=$ERRORS -f getBBoxEpisodesFromHTML.awk "$TV_EPISODE_HTML" |
#     sort -fu --key=4 --field-separator=\" >"$EPISODES_CSV"
BEGIN {
    # Print spreadsheet header
    printf(\
        "Title\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t"\
    )
    printf("Content_Type\tContent_ID\tItem_Type\tDate_Type\t")
    printf("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")
}

function convertDurationToHMS() {
    secs = duration
    mins = int(secs / 60)
    hrs = int(mins / 60)
    secs %= 60
    mins %= 60
    # Make duration a string
    duration = sprintf("%02d:%02d:%02d", hrs, mins, secs)
    # print "duration = " duration > "/dev/stderr"
}

{
    gsub(/&#160;/, " ")
    gsub(/&#163;/, "£")
    gsub(/&#193;/, "Á")
    gsub(/&#201;/, "É")
    gsub(/&#211;/, "Ó")
    gsub(/&#225;/, "á")
    gsub(/&#226;/, "â")
    gsub(/&#229;/, "å")
    gsub(/&#232;/, "è")
    gsub(/&#233;/, "é")
    gsub(/&#234;/, "ê")
    gsub(/&#235;/, "ë")
    gsub(/&#237;/, "í")
    gsub(/&#239;/, "ï")
    gsub(/&#243;/, "ó")
    gsub(/&#246;/, "ö")
    gsub(/&#248;/, "ø")
    gsub(/&#250;/, "ú")
    gsub(/&#253;/, "ý")
    gsub(/&#39;/, "'")
    gsub(/&amp;/, "\\&")
    gsub(/\\t/, "")
}

function clearShowVariables() {
    # Make sure no fields have been carried over due to missing keys
    # Only used during processing
    show_URL = ""
    title = ""
    yearRange = ""
    # Used in printing credits
    person_role = ""
    person_name = ""
    character_name = ""
    # Used in printing column data
    fullTitle = ""
    numberOfSeasons = ""
    numEpisodes = ""
    duration = ""
    showGenre = ""
    releaseYear = ""
    rating = ""
    showDescription = ""
    contentType = ""
    customId = ""
    itemType = ""
    dateType = ""
    show_showId = ""
    seasonId = ""
    seasonNumber = ""
    episodeNumber = ""
    #
    lastLineNum = ""
    firstLineNum = NR
}

function clearEpisodeVariables() {
    itemType = "episode"
    contentType = "tv_episode"
    episode_showId = ""
    episodeTitle = ""
    episodePath = ""
    episode_URL = ""
    shortEpisodeURL = ""
}

/^--BOS--$/ {
    # Only clearShowVariables at the start, leave them for episodes
    clearShowVariables()
}

# episode_URL: https://www.britbox.com/us/episode/15_Days_S1_E1_p07l24yd
/^episode_URL: / {
    episode_URL = $0
    sub(/^episode_URL: /, "", episode_URL)
    # print "episode_URL = " episode_URL > "/dev/stderr"
    shortEpisodeURL = episode_URL
    sub(/^https:\/\//, "", shortEpisodeURL)
    # print "shortEpisodeURL = " shortEpisodeURL > "/dev/stderr"
    # Goal: 15_Days_S01E001_Episode_1_p07l24yd > S01E001
    numFields = split(episode_URL, fld, "/")
    episodePath = fld[numFields]
    # print "episodePath = " episodePath > "/dev/stderr"
}

# itemType: movie
# itemType: show
# itemType: episode
/^itemType: / {
    itemType = $0
    sub(/^itemType: /, "", itemType)
    contentType = "tv_episode"
    totalEpisodes += 1
    # print "itemType = " itemType > "/dev/stderr"
    next
}

# showTitle: 15 Days
/^showTitle: / {
    showTitle = $0
    sub(/^showTitle: /, "", showTitle)
    # print "showTitle = " showTitle > "/dev/stderr"

    # "Maigret" needs to be revised to clarify timeframe
    if (showTitle ~ /^Maigret/) {
        if (episode_showId == "15928") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (1992-1993)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Maigret (1992-1993)"
        }
        else if (episode_showId == "15974") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (2016-2017)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Maigret (2016-2017)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> episode_showId = " episode_showId > "/dev/stderr"
    }

    # "Porridge" needs to be revised to avoid duplicate names
    if (showTitle == "Porridge") {
        if (episode_showId == "9509") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (1974-1977)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Porridge (1974-1977)"
        }
        else if (episode_showId == "14747") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (2016-2017)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Porridge (2016-2017)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> episode_showId = " episode_showId > "/dev/stderr"
    }

    # "The Moonstone" needs to be revised to avoid duplicate names
    if (showTitle == "The Moonstone") {
        if (episode_showId == "9283") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'The Moonstone (2016)'\n", showTitle\
            ) >> ERRORS
            showTitle = "The Moonstone (2016)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> episode_showId = " episode_showId > "/dev/stderr"
    }

    # "Wallander" needs to be revised to avoid duplicate names with MHz
    if (showTitle == "Wallander") {
        if (episode_showId == "24848") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Wallander (British)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Wallander (British)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> episode_showId = " episode_showId > "/dev/stderr"
    }
}

# episodeDescription: "Fulcher is faced with ... whereabouts"
# Note: Some descriptions may contain quotes
/^episodeDescription: / {
    episodeDescription = $0
    sub(/^episodeDescription: /, "", episodeDescription)
    gsub(/\\"/, "\"", episodeDescription)
    # print "episodeDescription = " episodeDescription > "/dev/stderr"
    next
}

# rating: TV-14
/^rating: / {
    dateType = "rating"
    rating = $0
    sub(/^rating: /, "", rating)
    # print "rating = " rating > "/dev/stderr"
    next
}

# seasonNumber: 1
/^seasonNumber: / {
    seasonNumber = $0
    sub(/^seasonNumber: /, "", seasonNumber)
    # print "seasonNumber = " seasonNumber > "/dev/stderr"
    next
}

# episodeNumber: 5
/^episodeNumber: / {
    episodeNumber = $0
    sub(/^episodeNumber: /, "", episodeNumber)
    # print "episodeNumber = " episodeNumber > "/dev/stderr"
    SnEp = sprintf("S%02dE%03d", seasonNumber, episodeNumber)
    next
}

# releaseYear: 2017
/^releaseYear: / {
    dateType = "releaseYear"
    releaseYear = $0
    sub(/^releaseYear: /, "", releaseYear)
    # print "releaseYear = " releaseYear > "/dev/stderr"
    next
}

# episodeTitle: Looking Good Dead
/^episodeTitle: / {
    episodeTitle = $0
    sub(/^episodeTitle: /, "", episodeTitle)
    # print "episodeTitle = " episodeTitle > "/dev/stderr"
    next
}

# episode_showId: 24474
/^episode_showId: / {
    episode_showId = $0
    sub(/^episode_showId: /, "", episode_showId)
    # print "episode_showId = " episode_showId > "/dev/stderr"
}

# customId: 24475
/^seasonId: / {
    seasonId = $0
    sub(/^seasonId: /, "", seasonId)
    # print "seasonId = " seasonId > "/dev/stderr"
    next
}

# episodeGenre: Drama
/^episodeGenre: / {
    episodeGenre = $0
    sub(/^episodeGenre: /, "", episodeGenre)
    # print "episodeGenre = " episodeGenre > "/dev/stderr"
    next
}

# duration: 2923
/^duration: / {
    duration = $0
    sub(/^duration: /, "", duration)
    lastLineNum = NR
    convertDurationToHMS()
    # print "duration = " duration > "/dev/stderr"
    next
}

# customId: p05wv7gy
/^customId: / {
    customId = $0
    sub(/^customId: /, "", customId)
    # print "customId = " customId > "/dev/stderr"
    next
}

# --EOE--
/^--EOE--$/ {
    # This should be the last line of every episode.
    # So finish processing and add line to spreadsheet

    # Turn episodeTitle into a HYPERLINK
    # Goal: 15_Days_S01E001_Episode_1_p07l24yd > 15 Days, S01E001, Episode 1
    fullTitle = "=HYPERLINK(\"" episode_URL "\";\"" showTitle ", " SnEp ", "\
        episodeTitle\
        "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # Report invalid episodeNumber
    if (episodeNumber + 0 == 0) {
        printf(\
            "==> Zero episodeNumber in \"%s: %s\" %s\n",
            showTitle,
            episodeTitle,
            shortEpisodeURL\
        ) >> ERRORS
    }

    # Print a spreadsheet line
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        fullTitle,
        numSeasons,
        numEpisodes,
        duration,
        episodeGenre,
        releaseYear,
        rating,
        episodeDescription\
    )
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        contentType,
        customId,
        itemType,
        dateType,
        episode_showId,
        seasonId,
        seasonNumber\
    )
    printf("%s\t%d\t%d\n", episodeNumber, firstLineNum, lastLineNum)
}

END {
    printf("In getBBoxEpisodesFromHTML.awk \n") > "/dev/stderr"

    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    printf(\
        "    Processed %d %s\n", totalEpisodes, pluralEpisodes\
    ) > "/dev/stderr"

    if (revisedTitles > 0) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf(\
            "%8d %s revised in %s\n", revisedTitles, plural, FILENAME\
        ) > "/dev/stderr"
    }
}
