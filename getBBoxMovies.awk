# Produce a movies spreadsheet from TV Movies html

# INVOCATION:
# awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES -v RAW_CREDITS=$RAW_CREDITS \
#   -f getBBoxMoviesFromHTML.awk "$TV_MOVIE_HTML" |
#   sort -fu --key=4 --field-separator=\" >"$MOVIES_CSV"
BEGIN {
    # Print spreadsheet header
    printf(\
        "Title\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t"\
    )
    printf("Content_Type\tContent_ID\tItem_Type\tDate_Type\t")
    printf("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")
}

function clearShowVariables() {
    # Make sure no fields have been carried over due to missing keys
    # Only used during processing
    show_URL = ""
    showTitle = ""
    title = ""
    episodeTitle = ""
    yearRange = ""
    # Used in printing credits
    person_role = ""
    person_name = ""
    character_name = ""
    # Used in printing column data
    hyperTitle = ""
    numberOfSeasons = ""
    numEpisodes = ""
    duration = ""
    showGenre = ""
    allYears = ""
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

/^--BO[MS]--$/ {
    clearShowVariables()
    next
}

# show_URL: https://www.britbox.com/us/movie/A_Christmas_Carol_p00z2f5m
/^show_URL: / {
    show_URL = $0
    sub(/^show_URL: /, "", show_URL)
    # print "show_URL = " show_URL > "/dev/stderr"
    next
}

# showTitle: 300 Years of French and Saunders
/^showTitle: / {
    title = $0
    sub(/^.*Title: /, "", title)
    # print "title = " title > "/dev/stderr"
    next
}

# itemType: movie
# itemType: show
# itemType: episode
/^itemType: / {
    itemType = $0
    sub(/^itemType: /, "", itemType)
    contentType = "tv_movie"
    totalMovies += 1
    # print "itemType = " itemType > "/dev/stderr"
    next
}

# showDescription: "Comedy ... lots of wigs."
# Some descriptions may contain quotes
/^showDescription: / {
    showDescription = $0
    sub(/^showDescription: /, "", showDescription)
    gsub(/\\"/, "\"", showDescription)
    next
}

# showGenre: Drama
/^showGenre: / {
    showGenre = $0
    sub(/^showGenre: /, "", showGenre)
    # print "showGenre = " showGenre > "/dev/stderr"
    next
}

# "name": "O15274_Movie Subscription HD-1080 Any User - Movies",
/_Movie Subscription/ { next }

# person_role: actor
/^person_role: / {
    person_role = $0
    sub(/^person_role: /, "", person_role)
    # print "person_role = " person_role > "/dev/stderr"
    next
}

# person_name: Michael Hordern
/^person_name: / {
    person_name = $0
    sub(/^person_name: /, "", person_name)
    # print "person_name = " person_name > "/dev/stderr"
    next
}

# character_name: Scrooge
/^character_name: / {
    character_name = $0
    sub(/^character_name: /, "", character_name)
    sub(/^ */, "", character_name)
    sub(/ *$/, "", character_name)
    printf(\
        "%s\t%s\ttv_movie\t%s\t%s\n",
        person_name,
        person_role,
        title,
        character_name\
    ) >> RAW_CREDITS
    # print "character_name = " character_name > "/dev/stderr"
    next
}

# rating: TV-14
/^rating: / {
    rating = $0
    sub(/^rating: /, "", rating)
    # print "rating = " rating > "/dev/stderr"
    next
}

# releaseYear: 2017
/^releaseYear: / {
    releaseYear = $0
    sub(/^releaseYear: /, "", releaseYear)
    # print "releaseYear = " releaseYear > "/dev/stderr"
    allYears = allYears " " releaseYear
    # print "allYears = " title " " allYears > "/dev/stderr"
    next
}

# customId: p05wv7gy
/^customId: / {
    customId = $0
    sub(/^customId: /, "", customId)
    # print "customId = " customId > "/dev/stderr"
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

# --EOM--
/^--EOM--$/ {
    # This should be the last line of every movie.
    # So finish processing and add line to spreadsheet

    numYears = split(allYears, yrs, " ")
    firstYear = yrs[1]
    lastYear = yrs[1]

    # print "releaseYearEnd = " showTitle " " releaseYear > "/dev/stderr"
    # print "allYearsEnd = " showTitle " " allYears "\n" > "/dev/stderr"
    if (numYears == 0) {
        print "==> No releaseYear in " show_URL >> ERRORS
        dateType = "releaseYear"
        releaseYear = ""
    }
    else if (numYears == 1) {
        # This should always be the case for movies.
        dateType = "releaseYear"
        # Keep original releaseYear
    }
    else {
        for (i = 1; i <= numYears; ++i) {
            # print "==> Found releaseYear " i " " yrs[i] > "/dev/stderr"
            if (yrs[i] < firstYear) { firstYear = yrs[i] }

            if (yrs[i] > lastYear) { lastYear = yrs[i] }
        }

        if (firstYear != lastYear) {
            dateType = "yearRange"
            releaseYear = firstYear " - " lastYear
        }
        else {
            # It was a false positive
            print "==> Multiple identical releaseYears in " showTitle >> ERRORS
            dateType = "releaseYear"
            releaseYear = firstYear
        }
    }

    # "A Midsummer Night's Dream" needs to be revised to avoid duplicate names
    if (title == "A Midsummer Night's Dream") {
        if (customId == "p089tsfc") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'A Midsummer Night's Dream (1981)'\n",
                title\
            ) >> ERRORS
            title = "A Midsummer Night's Dream (1981)"
            # print "==> revisedTitle = " title > "/dev/stderr"
        }
        else if (customId == "p05t7hx2") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'A Midsummer Night's Dream (2016)'\n",
                title\
            ) >> ERRORS
            title = "A Midsummer Night's Dream (2016)"
            # print "==> revisedTitle = " title > "/dev/stderr"
        }
    }

    # Save titles for use in BBox_uniqTitles
    print title >> RAW_TITLES
    # print "title = " title > "/dev/stderr"

    # Turn title into a HYPERLINK
    hyperTitle = "=HYPERLINK(\"" show_URL "\";\"" title "\")"
    # print "hyperTitle = " hyperTitle > "/dev/stderr"

    # Print a spreadsheet line
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        hyperTitle,
        numberOfSeasons,
        numEpisodes,
        duration,
        showGenre,
        releaseYear,
        rating,
        showDescription\
    )
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        contentType,
        customId,
        itemType,
        dateType,
        show_showId,
        seasonId,
        seasonNumber\
    )

    printf("%s\t%d\t%d\n", episodeNumber, firstLineNum, lastLineNum)
    next
}

END {
    printf("In getBBoxMoviesFromHTML.awk \n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    printf("    Processed %d %s\n", totalMovies, pluralMovies) > "/dev/stderr"

    if (revisedTitles > 0) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf(\
            "%8d %s revised in %s\n", revisedTitles, plural, FILENAME\
        ) > "/dev/stderr"
    }
}
