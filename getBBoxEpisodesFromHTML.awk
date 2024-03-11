# Produce an episode spreadsheet from TV Episodes html

# INVOCATION:
# awk -v ERRORS=$ERRORS -f getBBoxEpisodesFromHTML.awk "$TV_EPISODE_HTML" |
#     sort -fu --key=4 --field-separator=\" >"$EPISODES_CSV"
BEGIN {
    # Print spreadsheet header
    printf(\
        "Title\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t"\
    )
    printf("Content_Type\tContent_ID\tItem_Type\tDate_Type\tOriginal_Date\t")
    printf("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")
}

{
    gsub(/&#160;/, " ")
    gsub(/&#163;/, "£")
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
}

# "/tv/genres/Mystery"
/"\/tv\/genres\// {
    split($0, fld, "/")
    genre = fld[4]
    sub(/".*/, "", genre)
    # print "genre = " genre > "/dev/stderr"
}

# "type": "episode",
/"type": "episode",/ {
    # Make sure no fields have been carried over due to missing keys
    # Only used during processing
    episodeName = ""
    episodePath = ""
    full_URL = ""
    showTitle = ""
    SnEp = ""
    yearRange = ""
    # Used in printing column data
    fullTitle = ""
    numSeasons = ""
    numEpisodes = ""
    duration = ""
    year = ""
    rating = ""
    description = ""
    contentId = ""
    dateType = ""
    originalDate = ""
    showId = ""
    seasonId = ""
    seasonNumber = ""
    episodeNumber = ""
    lastLineNum = ""
    #
    contentType = "tv_episode"
    itemType = "episode"
    #
    firstLineNum = NR
}

# "shortDescription": "A young Rhys is shot dead in the house. Rewind 15 days and we meet four siblings and their families as they arrive at an isolated farmhouse to scatter their mother&#39;s ashes.",
#
# Note: Some descripotions may contain quotes
/"shortDescription": "/ {
    sub(/.*"shortDescription": "/, "")
    sub(/",$/, "")
    description = $0
    # print "description = " description > "/dev/stderr"
}

# "code": "TVPG-TV-PG",
/"code": "TVPG-/ {
    split($0, fld, "\"")
    rating = fld[4]
    sub(/TVPG-/, "", rating)
    # print "rating = " rating > "/dev/stderr"
}

# "path": "/episode/15_Days_S1_E1_p07l24yd",
/"path": "\/episode\// {
    # Goal: 15_Days_S01E001_Episode_1_p07l24yd > S01E001
    split($0, fld, "\"")
    episodePath = fld[4]
    full_URL = "https://www.britbox.com/us" episodePath
    # print "full_URL = " full_URL > "/dev/stderr"
    numFields = split(episodePath, fld, "_")
    seasonNumber = fld[numFields - 2]
    sub(/S/, "", seasonNumber)
    # print "seasonNumber = " seasonNumber > "/dev/stderr"
    episodeNumber = fld[numFields - 1]
    sub(/E/, "", episodeNumber)
    # print "episodeNumber = " episodeNumber > "/dev/stderr"
    SnEp = sprintf("S%02dE%03d", seasonNumber, episodeNumber)
}

# "releaseYear": 2019,
/"releaseYear": / {
    dateType = "releaseYear"
    split($0, fld, "\"")
    year = fld[3]
    sub(/: /, "", year)
    sub(/,.*/, "", year)
    # print "year = " year > "/dev/stderr"
}

# "episodeName": "Episode 1",
/"episodeName": "/ {
    split($0, fld, "\"")
    episodeName = fld[4]
    # print "episodeName = " episodeName > "/dev/stderr"
}

# "showId": "24474",
/"showId": / {
    split($0, fld, "\"")
    showId = fld[4]
    # print "showId = " showId > "/dev/stderr"
}

# "showTitle": "15 Days",
/"showTitle": / {
    split($0, fld, "\"")
    showTitle = fld[4]
    # print "showTitle = " showTitle > "/dev/stderr"

    # "Maigret" needs to be revised to clarify timeframe
    if (showTitle ~ /^Maigret/) {
        if (showId == "15928") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (1992-1993)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Maigret (1992-1993)"
        }
        else if (showId == "15974") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (2016-2017)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Maigret (2016-2017)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> showId = " showId > "/dev/stderr"
    }

    # "Porridge" needs to be revised to avoid duplicate names
    if (showTitle == "Porridge") {
        if (showId == "9509") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (1974-1977)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Porridge (1974-1977)"
        }
        else if (showId == "14747") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (2016-2017)'\n", showTitle\
            ) >> ERRORS
            showTitle = "Porridge (2016-2017)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> showId = " showId > "/dev/stderr"
    }

    # "The Moonstone" needs to be revised to avoid duplicate names
    if (showTitle == "The Moonstone") {
        if (showId == "9283") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'The Moonstone (2016)'\n", showTitle\
            ) >> ERRORS
            showTitle = "The Moonstone (2016)"
        }

        # print "==> showTitle = " showTitle > "/dev/stderr"
        # print "==> showId = " showId > "/dev/stderr"
    }
}

# "seasonId": "24475",
/"seasonId": / {
    split($0, fld, "\"")
    seasonId = fld[4]
    # print "seasonId = " seasonId > "/dev/stderr"
}

# "duration": 2690,
/"duration": / {
    split($0, fld, "\"")
    seconds = fld[3]
    sub(/: /, "", seconds)
    sub(/,.*/, "", seconds)
    duration = "0:" int(seconds / 60)
    # print "duration = " duration > "/dev/stderr"
}

# "customId": "p07kvw8d",
/"customId": "/ {
    totalEpisodes += 1
    lastLineNum = NR
    split($0, fld, "\"")
    contentId = fld[4]
    # print "contentId = " contentId > "/dev/stderr"

    # This should be the last line of every episode.
    # So finish processing and add line to spreadsheet

    # Turn episodeName into a HYPERLINK
    # Goal: 15_Days_S01E001_Episode_1_p07l24yd > 15 Days, S01E001, Episode 1
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" showTitle ", " SnEp ", "\
        episodeName\
        "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # Print a spreadsheet line
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        fullTitle,
        numSeasons,
        numEpisodes,
        duration,
        genre,
        year,
        rating,
        description\
    )
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        contentType,
        contentId,
        itemType,
        dateType,
        originalDate,
        showId,
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
