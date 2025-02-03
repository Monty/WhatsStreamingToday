# Produce a shows spreadsheet from TV Shows html

# INVOCATION:
# awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES -v RAW_CREDITS=$RAW_CREDITS \
#   -f getBBoxShowsFromHTML.awk "$TV_SHOW_HTML" |
#   sort -fu --key=4 --field-separator=\" >"$SHOWS_CSV"
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

/^--BO[MS]--$/ { clearShowVariables() }

# show_URL: https://www.britbox.com/us/show/A_Confession_p0891f13
/^show_URL: / {
    show_URL = $0
    sub(/^show_URL: /, "", show_URL)
    # print "show_URL = " show_URL > "/dev/stderr"
    next
}

# showTitle: A Confession
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
    contentType = "tv_show"
    totalShows += 1
    # print "itemType = " itemType > "/dev/stderr"
    next
}

# showDescription: "Martin Freeman stars ... O’Callaghan"
# Some descriptions may contain quotes
/^showDescription: / {
    showDescription = $0
    sub(/^showDescription: /, "", showDescription)
    gsub(/\\"/, "\"", showDescription)
    next
}

# showGenre: Mystery
/^showGenre: / {
    showGenre = $0
    sub(/^showGenre: /, "", showGenre)
    # print "showGenre = " showGenre > "/dev/stderr"
    next
}

# person_role: actor
/^person_role: / {
    person_role = $0
    sub(/^person_role: /, "", person_role)
    # print "person_role = " person_role > "/dev/stderr"
    next
}

# person_name: Tom Rhys Harries
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
        "%s\t%s\ttv_show\t%s\t%s\n",
        person_name,
        person_role,
        title,
        character_name\
    ) >> RAW_CREDITS
    # print "character_name = " character_name > "/dev/stderr"
    next
}

# rating: TV-MA
/^rating: / {
    dateType = "rating"
    rating = $0
    sub(/^rating: /, "", rating)
    # print "rating = " rating > "/dev/stderr"
    next
}

# "YearRange": 2019,
# "YearRange": "1992 - 2010",
/"YearRange": "/ {
    dateType = "yearRange"
    split($0, fld, "\"")
    yearRange = fld[4]
    releaseYear = yearRange
    # print "yearRange = \"" yearRange "\""> "/dev/stderr"
}

# releaseYear: 2017
/^releaseYear: / {
    dateType = "releaseYear"
    releaseYear = $0
    sub(/^releaseYear: /, "", releaseYear)
    # print "releaseYear = " releaseYear > "/dev/stderr"
    next
}

# customId: p07kvw8d
/^customId: / {
    customId = $0
    sub(/^customId: /, "", customId)
    # print "customId = " customId > "/dev/stderr"
    next
}

# show_showId: 24474
/^show_showId: / {
    show_showId = $0
    sub(/^show_showId: /, "", show_showId)
    # print "show_showId = " show_showId > "/dev/stderr"
    next
}

# numberOfSeasons: 2
/^numberOfSeasons: / {
    numberOfSeasons = $0
    sub(/^numberOfSeasons: /, "", numberOfSeasons)
    # print "numberOfSeasons = " numberOfSeasons > "/dev/stderr"
    next
}

# --EOS--
/^--EOS--$/ {
    lastLineNum = NR

    # This should be the last line of every show.
    # So finish processing and add line to spreadsheet

    # "Maigret" needs to be revised to clarify timeframe
    if (title ~ /^Maigret/) {
        if (show_showId == "15928") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (1992-1993)'\n", title\
            ) >> ERRORS
            title = "Maigret (1992-1993)"
        }
        else if (show_showId == "15974") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (2016-2017)'\n", title\
            ) >> ERRORS
            title = "Maigret (2016-2017)"
        }

        #print "==> revisedTitle = " title > "/dev/stderr"
        # print "==> show_showId = " show_showId > "/dev/stderr"
    }

    # "Porridge" needs to be revised to avoid duplicate names
    if (title == "Porridge") {
        if (show_showId == "9509") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (1974-1977)'\n", title\
            ) >> ERRORS
            title = "Porridge (1974-1977)"
        }
        else if (show_showId == "14747") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (2016-2017)'\n", title\
            ) >> ERRORS
            title = "Porridge (2016-2017)"
        }

        #print "==> revisedTitle = " title > "/dev/stderr"
        # print "==> show_showId = " show_showId > "/dev/stderr"
    }

    # "The Moonstone" needs to be revised to avoid duplicate names
    if (title == "The Moonstone") {
        if (show_showId == "9283") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'The Moonstone (2016)'\n", title\
            ) >> ERRORS
            title = "The Moonstone (2016)"
        }

        #print "==> revisedTitle = " title > "/dev/stderr"
        # print "==> show_showId = " show_showId > "/dev/stderr"
    }

    # "Wallander" needs to be revised to avoid duplicate names with MHz
    if (title == "Wallander") {
        if (show_showId == "24848") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Wallander (British)'\n", title\
            ) >> ERRORS
            title = "Wallander (British)"
        }

        #print "==> revisedTitle = " title > "/dev/stderr"
        # print "==> show_showId = " show_showId > "/dev/stderr"
    }

    # Save titles for use in BBox_uniqTitles
    print title >> RAW_TITLES
    # print "title = " title > "/dev/stderr"

    # Turn title into a HYPERLINK
    fullTitle = "=HYPERLINK(\"" show_URL "\";\"" title "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # Print a spreadsheet line
    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
        fullTitle,
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
}

END {
    printf("In getBBoxShowsFromHTML.awk \n") > "/dev/stderr"

    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    printf("    Processed %d %s\n", totalShows, pluralShows) > "/dev/stderr"

    if (revisedTitles > 0) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf(\
            "%8d %s revised in %s\n", revisedTitles, plural, FILENAME\
        ) > "/dev/stderr"
    }
}
