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

# <title>300 Years of French and Saunders - Comedy | BritBox</title>
/<title>/ {
    # Make sure no fields have been carried over due to missing keys
    # Only used during processing
    full_URL = ""
    year = ""
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
    year = ""
    rating = ""
    description = ""
    contentType = ""
    contentId = ""
    itemType = ""
    dateType = ""
    originalDate = ""
    showId = ""
    seasonId = ""
    seasonNumber = ""
    episodeNumber = ""
    lastLineNum = ""
    #
    firstLineNum = NR
    # Grab movie title
    split($0, fld, "[<>]")
    title = fld[3]
    sub(/ - .*/, "", title)
}

# <meta name="description" content="Comedy dream team Dawn French and Jennifer Saunders reunite for the first time in ten years for a thirtieth-anniversary show bursting mirth, mayhem, And wigs. Lots and lots of wigs." />
#
# Some descripotions may contain quotes
#
# <meta name="description" content="Since "A Christmas Carol" was first published   in 1843, the name of Ebenezer Scrooge has been famous throughout the world. See       Michael Hordern&#39;s stunning portrayal of the miserly misanthrope being shown the   error of his ways in this iconic adaptation." />
/<meta name="description" / {
    sub(/.*name="description" content="/, "")
    sub(/" \/>.*/, "")
    description = $0
}

# <link rel="canonical" href="https://www.britbox.com/us/movie/300_Years_of_French_and_Saunders_p05wv7gy" />
/<link rel="canonical" / {
    split($0, fld, "\"")
    full_URL = fld[4]
    # print "full_URL = " full_URL > "/dev/stderr"
}

# "type": "movie",
/"type": "/ {
    contentType = "tv_movie"
    split($0, fld, "\"")
    itemType = fld[4]
    totalMovies += 1
    # print "itemType = " itemType > "/dev/stderr"
}

# "/movies/genres/Comedy"
/"\/movies\/genres\// {
    split($0, fld, "/")
    genre = fld[4]
    sub(/".*/, "", genre)
}

# "name": "O15274_Movie Subscription HD-1080 Any User - Movies",
/_Movie Subscription/ { next }

# "role": "actor",
/"role": "/ {
    split($0, fld, "\"")
    person_role = fld[4]
    # print "person_role = " person_role > "/dev/stderr"
}

# "name": "Michael Hordern",
/"name": "/ {
    split($0, fld, "\"")
    person_name = fld[4]
    # print "person_name = " person_name > "/dev/stderr"
}

# "character": "Scrooge"
/"character": "/ {
    split($0, fld, "\"")
    character_name = fld[4]
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

# "code": "TVPG-TV-14",
/"code": "TVPG-/ {
    split($0, fld, "\"")
    rating = fld[4]
    sub(/TVPG-/, "", rating)
}

# "releaseYear": 2017,
/"releaseYear": / {
    dateType = "releaseYear"
    split($0, fld, "\"")
    year = fld[3]
    sub(/: /, "", year)
    sub(/,.*/, "", year)
}

# "customId": "p05wv7gy",
/"customId": "/ {
    split($0, fld, "\"")
    contentId = fld[4]
    # print "contentId = " contentId > "/dev/stderr"
}

# <b>Duration: </b>48 min
/<b>Duration: </ {
    lastLineNum = NR
    split($0, fld, "[<>]")
    duration = fld[5]
    sub(/ .*/, "", duration)
    duration = "0:" duration
    # print "duration = " duration > "/dev/stderr"

    # This should be the last line of every movie.
    # So finish processing and add line to spreadsheet

    # "A Midsummer Night's Dream" needs to be revised to avoid duplicate names
    if (title == "A Midsummer Night's Dream") {
        if (contentId == "p089tsfc") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'A Midsummer Night's Dream (1981)'\n",
                title\
            ) >> ERRORS
            title = "A Midsummer Night's Dream (1981)"
            # print "==> revisedTitle = " title > "/dev/stderr"
        }
        else if (contentId == "p05t7hx2") {
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
