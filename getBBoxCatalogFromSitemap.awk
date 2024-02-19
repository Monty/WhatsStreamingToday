# Produce a raw data spreadsheet from fields in BritBox Catalog --  apple_catalogue_feed.xml
# The "showContentId" from "tv_show" items are needed to process "tv_season" and "tv_episode" items,
# so you should sort the catalog to ensure items are in the proper order.

# INVOCATION:
#    awk -v ERRORS=$ERRORS -v IDS_SEASONS=$IDS_SEASONS -v IDS_EPISODES=$IDS_EPISODES \
#        -v RAW_TITLES=$RAW_TITLES -v RAW_CREDITS=$RAW_CREDITS -f getBBoxCatalogFromSitemap.awk \
#        $SORTED_SITEMAP >$CATALOG_SPREADSHEET

# Field numbers
#     1 Sortkey       2 Title         3 Seasons          4 Episodes         5 Duration      6 Genre
#     7 Year          8 Rating        9 Description     10 Content_Type    11 Content_ID   12 Show_Type
#    13 Date_Type    14 Date_Type    15 Show_ID         16 Season_ID       17 Sn_#         18 Ep_#
#    19 1st_#        20 Last_#
BEGIN {
    # Print spreadsheet header
    printf(\
        "Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t"\
    )
    printf("Content_Type\tContent_ID\tShow_Type\tDate_Type\tOriginal_Date\t")
    printf("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")

    # Print credits  header
    printf(\
        "Person\tRole\tShow_Type\tShow_Title\tCharacter_Name\n"\
    ) > RAW_CREDITS
}

# Process credits
/<credit role=/ {
    split($0, fld, "\"")
    person_role = fld[2]
    next
}

#
/<name locale="en-US">/ {
    split($0, fld, "[<>]")
    person_name = fld[3]
    next
}

#
/<characterName locale="en-US">/ {
    split($0, fld, "[<>]")
    char_name = fld[3]
    sub(/^[[:space:]]+/, "", char_name)
    # Special case
    # Fix anomalous line with embedded tab ".^I Charlotte Edalji" in "Arthur and George"
    sub(/^.[[:space:]]+/, "", char_name)
    next
}

#
/<\/credit>/ {
    if (contentType == "movie" || contentType == "tv_show") {
        totalCredits += 1
        # "movie" is too common to be in a key field, use "tv_movie"
        contentType == "movie"\
            ? tvShowType = "tv_movie"\
            : tvShowType = contentType
        printf(\
            "%s\t%s\t%s\t%s\t%s\n",
            person_name,
            person_role,
            tvShowType,
            title,
            char_name\
        ) >> RAW_CREDITS
    }

    person_role = ""
    person_name = ""
    char_name = ""
    next
}

# Don't use Canadian ratings
/<rating systemCode="ca-tv">/ { next }

# Don't use pubDate - it's too random to be useful
# <pubDate>2020-06-05T21:51:00Z</pubDate>
/<pubDate>/ { next }

# Don't use "cover_artwork_horizontal"
# <artwork url="https://britbox-images-prod.s3-eu-west-1.amazonaws.com/3840x2160px/p05wv7gy.png" type="cover_artwork_horizontal" />
/<artwork url=.*type="cover_artwork_horizontal"/ { next }

# Grab contentType & contentId
# <item contentType="tv_episode" contentId="p079sxm9">
/<item contentType="/ {
    firstLineNum = NR
    split($0, fld, "\"")
    contentType = fld[2]
    contentId = fld[4]
    # print "contentType = " contentType > "/dev/stderr"
    # print "contentId = " contentId > "/dev/stderr"
    #
    # Make sure no fields will be carried over due to missing keys
    sortkey = ""
    title = ""
    genre = ""
    rating = ""
    showType = ""
    duration = ""
    dateType = ""
    originalDate = ""
    showContentId = ""
    seasonContentId = ""
    seasonNumber = ""
    episodeNumber = ""
    description = ""
    # Generated fields
    year = ""
    # New fields that haven't been created yet
    numSeasons = ""
    numEpisodes = ""
}

# Grab title
# <title locale="en-US">Frequent Flyers</title>
/<title locale="en-US">/ {
    split($0, fld, "[<>]")
    title = fld[3]
    # print "title = " title > "/dev/stderr"
    gsub(/&amp;/, "\\&", title)
    sub(/[[:space:]]+$/, "", title)
}

# Grab genre
# <genre>drama</genre>
/<genre>/ {
    split($0, fld, "[<>]")
    genre = fld[3]
    genre = toupper(substr(genre, 1, 1)) substr(genre, 2)
    sub(/Sci_fi/, "Sci-Fi", genre)
    sub(/Special_interest/, "Special interest", genre)
    # print "genre = " genre > "/dev/stderr"
}

# Grab description
# <description>Set in the beautiful Yorkshire Dales, ...word.</description>
/<description>/ {
    split($0, fld, "[<>]")
    description = fld[3]
    # print "description = " description > "/dev/stderr"
    gsub(/&amp;/, "\\&", description)
    gsub(/\t/, " - ", description)
}

# Grab rating
# <rating systemCode="us-tv">TV-PG</rating>
/<rating systemCode=/ {
    split($0, fld, "[<>]")
    rating = fld[3]
    # print "rating = " rating > "/dev/stderr"
}

# Grab type
# <type>series</type>
/<type>/ {
    split($0, fld, "[<>]")
    showType = fld[3]
    # print "showType = " showType > "/dev/stderr"
}

# Grab duration
# <duration>3000</duration>
/<duration>/ {
    split($0, fld, "[<>]")
    seconds = fld[3]
    secs = seconds % 60
    mins = int(seconds / 60 % 60)
    hrs = int(seconds / 3600)
    duration = sprintf("%02d:%02d:%02d", hrs, mins, secs)

    if (duration == "00:00:00") duration = ""

    # print "duration = " seconds " seconds = " duration > "/dev/stderr"
}

# Grab originalDate
# <originalAirDate>1978-03-25</originalAirDate>
# <originalPremiereDate>1978-01-08</originalPremiereDate>
# <originalReleaseDate>2017-12-25</originalReleaseDate>
/<original.*Date>/ {
    split($0, fld, "[<>]")
    dateType = fld[2]
    sub(/original/, "", dateType)
    originalDate = fld[3]
    year = substr(originalDate, 1, 4)
    # print "dateType = " dateType > "/dev/stderr"
    # print "originalDate = " originalDate > "/dev/stderr"
    # print "year = " year > "/dev/stderr"
}

# Grab showContentId
# <showContentId>b008yjd9</showContentId>
/<showContentId>/ {
    split($0, fld, "[<>]")
    showContentId = fld[3]
    # print "showContentId = " showContentId > "/dev/stderr"
}

# Grab seasonContentId
# <seasonContentId>p0318ps9</seasonContentId>
/<seasonContentId>/ {
    split($0, fld, "[<>]")
    seasonContentId = fld[3]
    # print "seasonContentId = " seasonContentId > "/dev/stderr"
}

# Grab seasonNumber
# <seasonNumber>1</seasonNumber>
/<seasonNumber>/ {
    split($0, fld, "[<>]")
    seasonNumber = fld[3]
    # print "seasonNumber = " seasonNumber > "/dev/stderr"
}

# Grab episodeNumber
# <episodeNumber>10</episodeNumber>
/<episodeNumber>/ {
    split($0, fld, "[<>]")
    episodeNumber = fld[3]
    # print "episodeNumber = " episodeNumber > "/dev/stderr"
}

# Do any special end of item processing, then print raw data spreadsheet row
/<\/item>/ {
    lastLineNum = NR

    # <title locale="en-US">Too Old… Or Too Nosy?</title>
    if (contentId == "p04dqy0m") {
        # print "title = " title > "/dev/stderr"
        title = "Too Old... Or Too Nosy?"
    }

    # <title locale="en-US">Llŷn Peninsula</title
    if (contentId == "m000wn8z") {
        # print "title = " title > "/dev/stderr"
        title = "Llyn Peninsula"
    }

    # <title locale="en-US">Boylé Boylé Boylé</title>
    if (contentId == "p096kt29") {
        # print "title = " title > "/dev/stderr"
        title = "Boyle Boyle Boyle"
    }

    # "The Moonstone" needs to be revised to avoid duplicate names
    # "The Moonstone (1972) already has an embedded date
    if (title == "The Moonstone") {
        if (contentId == "FS_b0824cbr") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'The Moonstone (2016)'\n", title\
            ) >> ERRORS
            title = "The Moonstone (2016)"
        }

        # print "==> title = " title > "/dev/stderr"
        # print "==> contentId = " contentId > "/dev/stderr"
    }

    # "Porridge" needs to be revised to avoid duplicate names
    if (title == "Porridge") {
        if (contentId == "b006m9kn") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (1974-1977)'\n", title\
            ) >> ERRORS
            title = "Porridge (1974-1977)"
        }
        else if (contentId == "p05dsmwl") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Porridge (2016-2017)'\n", title\
            ) >> ERRORS
            title = "Porridge (2016-2017)"
        }

        # print "==> title = " title > "/dev/stderr"
        # print "==> contentId = " contentId > "/dev/stderr"
    }

    # "A Midsummer Night's Dream" needs to be revised to avoid duplicate names
    if (title == "A Midsummer Night's Dream") {
        if (contentId == "p089tsfc") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'A Midsummer Night's Dream (1981)'\n",
                title\
            ) >> ERRORS
            title = "A Midsummer Night's Dream (1981)"
        }
        else if (contentId == "p05t7hx2") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'A Midsummer Night's Dream (2016)'\n",
                title\
            ) >> ERRORS
            title = "A Midsummer Night's Dream (2016)"
        }

        # print "==> title = " title > "/dev/stderr"
        # print "==> contentId = " contentId > "/dev/stderr"
    }

    # "Maigret" needs to be revised to clarify timeframe
    if (title ~ /^Maigret/ && contentType == "tv_show") {
        if (contentId == "p05t7c9c") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (1992-1993)'\n", title\
            ) >> ERRORS
            title = "Maigret (1992-1993)"
        }
        else if (contentId == "p05vcgph") {
            revisedTitles += 1
            printf(\
                "==> Changed title '%s' to 'Maigret (2016-2017)'\n", title\
            ) >> ERRORS
            title = "Maigret (2016-2017)"
        }

        # print "==> title = " title > "/dev/stderr"
        # print "==> contentId = " contentId > "/dev/stderr"
    }

    if (contentType == "movie") {
        totalMovies += 1
        # print "\ntv_movie" > "/dev/stderr"
        # Wish I didn't have to do this, but "movie" is too common to be in a key field
        contentType = "tv_movie"
        sortkey = sprintf("%s (1) %s M %s", title, originalDate, contentId)
        # print "sortkey = " sortkey > "/dev/stderr"
        print title >> RAW_TITLES
    }

    if (contentType == "tv_show") {
        totalShows += 1
        # print "\ntv_show" > "/dev/stderr"
        showArray[totalShows] = contentId
        titleArray[totalShows] = title
        sortkey = sprintf("%s (1) S %s", title, contentId)
        # print "sortkey = " sortkey > "/dev/stderr"
        print title >> RAW_TITLES
        cmd1 = "grep -c " contentId " " IDS_SEASONS
        cmd1 | getline numSeasons
        close cmd1
        #
        cmd2 = "grep -c " contentId " " IDS_EPISODES
        cmd2 | getline numEpisodes
        close cmd2
    }

    if (contentType == "tv_season") {
        totalSeasons += 1
        # print "\ntv_season" > "/dev/stderr"
        for (i = 1; i <= totalShows; i++) {
            if (showArray[i] == showContentId) {
                showTitle = titleArray[i]
                break
            }
        }

        sortkey = sprintf(\
            "%s (2) S%02d %s", showTitle, seasonNumber, showContentId\
        )
        # Check that showContentId was actually found - if not, put parens around showTitle in sortkey
        if (showArray[i] != showContentId) {
            missingShowContentIds += 1
            printf(\
                "==> Missing showContentId for %s %s '%s' in show %s at line %d\n",
                contentType,
                contentId,
                title,
                showContentId,
                firstLineNum\
            ) >> ERRORS
            sortkey = sprintf(\
                "(%s) (2) S%02d %s", showTitle, seasonNumber, showContentId\
            )
        }

        # print "sortkey = " sortkey > "/dev/stderr"
        # Compose title
        title = sprintf("%s, S%02d, %s", showTitle, seasonNumber, title)
    }

    if (contentType == "tv_episode") {
        totalEpisodes += 1
        # print "\ntv_episode" > "/dev/stderr"
        for (i = 1; i <= totalShows; i++) {
            if (showArray[i] == showContentId) {
                showTitle = titleArray[i]
                break
            }
        }

        sortkey = sprintf(\
            "%s (2) S%02dE%03d %s",
            showTitle,
            seasonNumber,
            episodeNumber,
            showContentId\
        )
        # Check that showContentId was actually found - if not, put parens around showTitle in sortkey
        if (showArray[i] != showContentId) {
            missingShowContentIds += 1
            printf(\
                "==> Missing showContentId for %s %s '%s' in show %s at line %d\n",
                contentType,
                contentId,
                title,
                showContentId,
                firstLineNum\
            ) >> ERRORS
            sortkey = sprintf(\
                "(%s) (2) S%02dE%03d %s",
                showTitle,
                seasonNumber,
                episodeNumber,
                showContentId\
            )
        }

        # print "sortkey = " sortkey > "/dev/stderr"
        # Compose title
        title = sprintf(\
            "%s, S%02dE%03d, %s", showTitle, seasonNumber, episodeNumber, title\
        )
    }

    # Generate a link that will lead to the show on BritBox
    # https://www.britbox.com/us/movie/63_Up_p09668r0
    # https://www.britbox.com/us/movie/A_Childs_Christmases_in_Wales_b00pgr8x
    #
    # https://www.britbox.com/us/show/A_Confession_p0891f13
    # https://www.britbox.com/us/show/A_Touch_of_Frost_p04lpx3q
    #
    # https://www.britbox.com/us/show/A_Touch_of_Frost_p04lpx3q
    # https://www.britbox.com/us/show/Scott_and_Bailey_p046k2z1
    #
    showType_URL = contentType "/"
    sub(/tv_/, "", showType_URL)
    URL_Title = title
    gsub(/[[:punct:]]/, "", URL_Title)
    gsub(/[[:space:]]/, "_", URL_Title)
    full_URL = "https://www.britbox.com/us/" showType_URL URL_Title "_"\
        contentId
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" title "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # A seasonless "show" should have blank rather than 0 seasons
    if (showType == "seasonless") numSeasons = ""

    # If an "episode" sortkey or fullTitle contains "S00E" delete the "S00" part
    sub(/S00E/, "E", sortkey)
    sub(/S00E/, "E", fullTitle)
    # Print everything except tv_seasons
    if (contentType != "tv_season")
        printf(\
            "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%06d\t%06d\n",
            sortkey,
            fullTitle,
            numSeasons,
            numEpisodes,
            duration,
            genre,
            year,
            rating,
            description,
            contentType,
            contentId,
            showType,
            dateType,
            originalDate,
            showContentId,
            seasonContentId,
            seasonNumber,
            episodeNumber,
            firstLineNum,
            lastLineNum\
        )
}

END {
    printf("In getBBoxCatalogFromSitemap.awk\n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    totalCredits == 1 ? pluralCredits = "credit" : pluralCredits = "credits"
    #
    printf(\
        "    Processed %d %s, %d %s, %d %s, %d %s, %d %s\n",
        totalMovies,
        pluralMovies,
        totalShows,
        pluralShows,
        totalSeasons,
        pluralSeasons,
        totalEpisodes,
        pluralEpisodes,
        totalCredits,
        pluralCredits\
    ) > "/dev/stderr"

    if (missingShowContentIds > 0) {
        missingShowContentIds == 1\
            ? plural = "showContentId"\
            : plural = "showContentIds"
        printf(\
            "%8d missing %s in %s\n", missingShowContentIds, plural, FILENAME\
        ) > "/dev/stderr"
    }

    if (revisedTitles > 0) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf(\
            "%8d %s revised in %s\n", revisedTitles, plural, FILENAME\
        ) > "/dev/stderr"
    }
}
