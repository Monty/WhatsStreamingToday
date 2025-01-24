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
    printf("Content_Type\tContent_ID\tItem_Type\tDate_Type\tOriginal_Date\t")
    printf("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")
}

function clearShowVariables() {
    # Make sure no fields have been carried over due to missing keys
    # Only used during processing
    full_URL = ""
    title = ""
    # Used in printing credits
    person_role = ""
    person_name = ""
    character_name = ""
    # Used in printing column data
    fullTitle = ""
    numSeasons = ""
    numEpisodes = ""
    duration = ""
    genre = ""
    releaseYear = ""
    rating = ""
    description = ""
    contentType = ""
    customId = ""
    itemType = ""
    dateType = ""
    originalDate = ""
    showId = ""
    seasonId = ""
    seasonNumber = ""
    episodeNumber = ""
    #
    lastLineNum = ""
    firstLineNum = NR
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
    gsub(/&#239;/, "ï")
    gsub(/&#246;/, "ö")
    gsub(/&#248;/, "ø")
    gsub(/&#250;/, "ú")
    gsub(/&#253;/, "ý")
    gsub(/&#39;/, "'")
    gsub(/&amp;/, "\\&")
}

# title: 300 Years of French and Saunders
/^title: / {
    title = $0
    sub(/^title: /, "", title)
}

# description: "Comedy ... lots of wigs."
# Some descriptions may contain quotes
/^description: / {
    description = $0
    sub(/^description: /, "", description)
}

# full_URL: https://www.britbox.com/us/movie/A_Christmas_Carol_p00z2f5m
/^full_URL: / {
    full_URL = $0
    sub(/^full_URL: /, "", full_URL)
    # print "full_URL = " full_URL > "/dev/stderr"
}

# itemType: movie
/^itemType: / {
    itemType = $0
    sub(/^itemType: /, "", itemType)
    contentType = "tv_movie"
    totalMovies += 1
    # print "itemType = " itemType > "/dev/stderr"
}

# genre: Drama
/^genre: / {
    genre = $0
    sub(/^genre: /, "", genre)
    # print "genre = " genre > "/dev/stderr"
}

# "name": "O15274_Movie Subscription HD-1080 Any User - Movies",
/_Movie Subscription/ { next }

# person_role: actor
/^person_role: / {
    person_role = $0
    sub(/^person_role: /, "", person_role)
    # print "person_role = " person_role > "/dev/stderr"
}

# person_name: Michael Hordern
/^person_name: / {
    person_name = $0
    sub(/^person_name: /, "", person_name)
    # print "person_name = " person_name > "/dev/stderr"
}

# character_name: Scrooge
/^character_name: / {
    character_name = $0
    sub(/^character_name: /, "", character_name)
    sub(/\\t/, "", character_name)
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
}

# rating: TV-14
/^rating: / {
    dateType = "rating"
    rating = $0
    sub(/^rating: /, "", rating)
    # print "rating = " rating > "/dev/stderr"
}

# releaseYear: 2017
/^releaseYear: / {
    dateType = "releaseYear"
    releaseYear = $0
    sub(/^releaseYear: /, "", releaseYear)
    # print "releaseYear = " releaseYear > "/dev/stderr"
}

# customId: p05wv7gy
/^customId: / {
    customId = $0
    sub(/^customId: /, "", customId)
    # print "customId = " customId > "/dev/stderr"
}

# duration: 2923
/^duration: / {
    duration = $0
    sub(/^duration: /, "", duration)
    lastLineNum = NR
    duration = "0:" duration
    # print "duration = " duration > "/dev/stderr"

    # This should be the last line of every movie.
    # So finish processing and add line to spreadsheet

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
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" title "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # Print a spreadsheet line
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        fullTitle,
        numSeasons,
        numEpisodes,
        duration,
        genre,
        releaseYear,
        rating,
        description\
    )
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        contentType,
        customId,
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
