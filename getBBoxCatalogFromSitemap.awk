# Produce a raw data spreadsheet from fields in BritBox Catalog --  apple_catalogue_feed.xml
# The "showContentId" from "tv_show" items are needed to process "tv_season" and "tv_episode" items,
# so you should sort the catalog to ensure items are in the proper order.

# INVOCATION:
#    awk -v ERRORS=$ERRORS -v IDS_SEASONS=$IDS_SEASONS -v IDS_EPISODES=$IDS_EPISODES \
#        -v RAW_TITLES=$RAW_TITLES -v RAW_CREDITS=$RAW_CREDITS -f getBBoxCatalogFromSitemap.awk \
#        $SORTED_SITEMAP >$CATALOG_SPREADSHEET

# Field numbers
#     1 Sortkey       2 Title         3 Seasons          4 Episodes         5 Duration      6 Genre
#     7 Year          8 Rating        9 Description     10 Content_Type    11 Content_ID   12 Entity_ID
#    13 Show_Type    14 Date_Type    15 Original_Date   16 Show_ID         17 Season_ID    18 Sn_#
#    19 Ep_#         20 1st_#        21 Last_#

BEGIN {
    # Print spreadsheet header
    printf ("Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t")
    printf ("Content_Type\tContent_ID\tEntity_ID\tShow_Type\tDate_Type\tOriginal_Date\t")
    printf ("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")

    # Print credits  header
    printf ("Person\tRole\tShow_Type\tShow_Title\tCharacter_Name\n") > RAW_CREDITS
}

# Process credits
/<credit role=/ {
    split ($0,fld,"\"")
    person_role = fld[2]
    next
}
#
/<name locale="en-US">/ {
    split ($0,fld,"[<>]")
    person_name = fld[3]
    next
}
#
/<characterName locale="en-US">/ {
    split ($0,fld,"[<>]")
    char_name = fld[3]
    sub (/^[[:space:]]+/,"",char_name)
    # Special case
    # Fix anomalous line with embedded tab ".^I Charlotte Edalji" in "Arthur and George"
    sub (/^.[[:space:]]+/,"",char_name)
    next
}
#
/<\/credit>/ {
    if (contentType == "movie" || contentType == "tv_show") {
        totalCredits += 1
        # "movie" is too common to be in a key field, use "tv_movie"
        contentType == "movie" ? tvShowType = "tv_movie" : tvShowType = contentType
        printf ("%s\t%s\t%s\t%s\t%s\n", person_name, person_role, tvShowType, title, 
                char_name) >> RAW_CREDITS
    }
    person_role = ""
    person_name = ""
    char_name = ""
    next
}

# Don't use Canadian ratings
/<rating systemCode="ca-tv">/ {
    next
}

# Don't use pubDate - it's too random to be useful
# <pubDate>2020-06-05T21:51:00Z</pubDate>
/<pubDate>/ {
    next
}

# Don't use "cover_artwork_horizontal"
# <artwork url="https://britbox-images-prod.s3-eu-west-1.amazonaws.com/3840x2160px/p05wv7gy.png" type="cover_artwork_horizontal" />
/<artwork url=.*type="cover_artwork_horizontal"/ {
    next
}

# Grab contentType & contentId
# <item contentType="tv_episode" contentId="p079sxm9">
/<item contentType="/ {
    firstLineNum = NR
    split ($0,fld,"\"")
    contentType = fld[2]
    contentId = fld[4]
    # print "contentType = " contentType > "/dev/stderr"
    # print "contentId = " contentId > "/dev/stderr"
    #
    # Make sure no fields will be carried over due to missing keys
    sortkey = ""
    title = ""
    EntityId = ""
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
    split ($0,fld,"[<>]")
    title = fld[3]
    # print "title = " title > "/dev/stderr"
    gsub (/&amp;/,"\\&",title)
    sub (/[[:space:]]+$/,"",title)
}

# Grab genre
# <genre>drama</genre>
/<genre>/ {
    split ($0,fld,"[<>]")
    genre = fld[3]
    genre = toupper(substr(genre,1,1)) substr(genre,2)
    sub (/Sci_fi/,"Sci-Fi",genre)
    sub (/Special_interest/,"Special interest",genre)
    # print "genre = " genre > "/dev/stderr"
}

# Grab description
# <description>Set in the beautiful Yorkshire Dales, ...word.</description>
/<description>/ {
    split ($0,fld,"[<>]")
    description = fld[3]
    # print "description = " description > "/dev/stderr"
    gsub (/&amp;/,"\\&",description)
    gsub (/\t/," – ",description)
}

# Grab rating
# <rating systemCode="us-tv">TV-PG</rating>
/<rating systemCode=/ {
    split ($0,fld,"[<>]")
    rating = fld[3]
    # print "rating = " rating > "/dev/stderr"
}

# Grab type
# <type>series</type>
/<type>/ {
    split ($0,fld,"[<>]")
    showType = fld[3]
    # print "showType = " showType > "/dev/stderr"
}

# Grab duration
# <duration>3000</duration>
/<duration>/ {
    split ($0,fld,"[<>]")
    seconds = fld[3]
    secs = seconds % 60
    mins = int(seconds / 60 % 60)
    hrs = int(seconds / 3600)
    duration = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (duration == "00:00:00")
        duration = ""
    # print "duration = " seconds " seconds = " duration > "/dev/stderr"
}

# Grab originalDate
# <originalAirDate>1978-03-25</originalAirDate>
# <originalPremiereDate>1978-01-08</originalPremiereDate>
# <originalReleaseDate>2017-12-25</originalReleaseDate>
/<original.*Date>/ {
    split ($0,fld,"[<>]")
    dateType = fld[2]
    sub (/original/,"",dateType)
    originalDate = fld[3]
    year = substr (originalDate,1,4)
    # print "dateType = " dateType > "/dev/stderr"
    # print "originalDate = " originalDate > "/dev/stderr"
    # print "year = " year > "/dev/stderr"
}

# Grab showContentId
# <showContentId>b008yjd9</showContentId>
/<showContentId>/ {
    split ($0,fld,"[<>]")
    showContentId = fld[3]
    # print "showContentId = " showContentId > "/dev/stderr"
}

# Grab seasonContentId
# <seasonContentId>p0318ps9</seasonContentId>
/<seasonContentId>/ {
    split ($0,fld,"[<>]")
    seasonContentId = fld[3]
    # print "seasonContentId = " seasonContentId > "/dev/stderr"
}

# Grab seasonNumber
# <seasonNumber>1</seasonNumber>
/<seasonNumber>/ {
    split ($0,fld,"[<>]")
    seasonNumber = fld[3]
    # print "seasonNumber = " seasonNumber > "/dev/stderr"
}

# Grab episodeNumber
# <episodeNumber>10</episodeNumber>
/<episodeNumber>/ {
    split ($0,fld,"[<>]")
    episodeNumber = fld[3]
    # print "episodeNumber = " episodeNumber > "/dev/stderr"
}

# Grab EntityId from artwork
# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;jpg&apos;&amp;Quality=45&amp;ImageId=&apos;176236&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;16103&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
/<artwork url=.*EntityId=&apos;/ {
    sub (/.*EntityId=&apos;/,"")
    sub (/&apos.*/,"")
    EntityId = "_" $0
    # print "EntityId = " EntityId > "/dev/stderr"
}

# Do any special end of item processing, then print raw data spreadsheet row
/<\/item>/ {
    lastLineNum = NR

    # "The Moonstone" needs to be revised to avoid duplicate names
    if (title == "The Moonstone") {
        if (EntityId == "_9283") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'The Moonstone (2016)'\n", title) >> ERRORS
            title = "The Moonstone (2016)"
        }
        # print "==> title = " title > "/dev/stderr"
        # print "==> EntityId = " EntityId > "/dev/stderr"
    }

    # "Porridge" needs to be revised to avoid duplicate names
    if (title == "Porridge") {
        if (EntityId == "_9509") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Porridge (1974-1977)'\n", title) >> ERRORS
            title = "Porridge (1974-1977)"
        } else if (EntityId == "_14747") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Porridge (2016-2017)'\n", title) >> ERRORS
            title = "Porridge (2016-2017)"
        }
        # print "==> title = " title > "/dev/stderr"
        # print "==> EntityId = " EntityId > "/dev/stderr"
    }

    # "A Midsummer Night's Dream" needs to be revised to avoid duplicate names
    if (title == "A Midsummer Night's Dream") {
        if (EntityId == "_26179") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'A Midsummer Night\'s Dream (1981)'\n", title) >> ERRORS
            title = "A Midsummer Night's Dream (1981)"
        } else if (EntityId == "_15999") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'A Midsummer Night\'s Dream (2016)'\n", title) >> ERRORS
            title = "A Midsummer Night's Dream (2016)"
        }
        # print "==> title = " title > "/dev/stderr"
        # print "==> EntityId = " EntityId > "/dev/stderr"
    }

    # "Maigret" needs to be revised to clarify timeframe
    if (title ~ /^Maigret/ && contentType == "tv_show") {
        if (EntityId == "_15928") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Maigret (1992-1993)'\n", title) >> ERRORS
            title = "Maigret (1992-1993)"
        } else if (EntityId == "_15974") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Maigret (2016–2017)'\n", title) >> ERRORS
            title = "Maigret (2016–2017)"
        }
        # print "==> title = " title > "/dev/stderr"
        # print "==> EntityId = " EntityId > "/dev/stderr"
    }

    if (EntityId == "") {
        missingEntityIds += 1
        printf ("==> Missing EntityId for %s %s '%s' in show %s at line %d\n", contentType, contentId,
                title, showContentId, firstLineNum) >> ERRORS
    }

    if (contentType == "movie") {
        totalMovies += 1
        # print "\ntv_movie" > "/dev/stderr"
        # Wish I didn't have to do this, but "movie" is too common to be in a key field
        contentType = "tv_movie"
        sortkey = sprintf ("%s (1) %s M%s", title, originalDate, EntityId)
        # print "sortkey = " sortkey > "/dev/stderr"
        print title >> RAW_TITLES
    }

    if (contentType == "tv_show") {
        totalShows += 1
        # print "\ntv_show" > "/dev/stderr"
        showArray[totalShows] = contentId
        titleArray[totalShows] = title
        sortkey = sprintf ("%s (1) S%s %s", title, EntityId, contentId)
        # print "sortkey = " sortkey > "/dev/stderr"
        print title >> RAW_TITLES
        cmd1 = "grep -c " contentId " " IDS_SEASONS
        cmd1 | getline numSeasons
        close (cmd1)
        #
        cmd2 = "grep -c " contentId " " IDS_EPISODES
        cmd2 | getline numEpisodes
        close (cmd2)
    }

    if (contentType == "tv_season") {
        totalSeasons += 1
        # print "\ntv_season" > "/dev/stderr"
        for ( i = 1; i <= totalShows; i++ ) {
            if (showArray[i] == showContentId) {
                showTitle = titleArray[i]
                break
            }
        }
        sortkey = sprintf ("%s (2) S%02d %s", showTitle, seasonNumber, showContentId)
        # Check that showContentId was actually found - if not, put parens around showTitle in sortkey
        if (showArray[i] != showContentId) {
            missingShowContentIds += 1
            printf ("==> Missing showContentId for %s %s '%s' in show %s at line %d\n", contentType,
                    contentId, title, showContentId, firstLineNum) >> ERRORS
            sortkey = sprintf ("(%s) (2) S%02d %s", showTitle, seasonNumber, showContentId)
        } 
        # print "sortkey = " sortkey > "/dev/stderr"
        # Compose title
        title = sprintf ("%s, S%02d, %s", showTitle, seasonNumber, title)
    }

    if (contentType == "tv_episode") {
        totalEpisodes += 1
        # print "\ntv_episode" > "/dev/stderr"
        for ( i = 1; i <= totalShows; i++ ) {
            if (showArray[i] == showContentId) {
                showTitle = titleArray[i]
                break
            }
        }
        sortkey = sprintf ("%s (2) S%02dE%03d %s", showTitle, seasonNumber, episodeNumber,
                showContentId)
        # Check that showContentId was actually found - if not, put parens around showTitle in sortkey
        if (showArray[i] != showContentId) {
            missingShowContentIds += 1
            printf ("==> Missing showContentId for %s %s '%s' in show %s at line %d\n", contentType,
                    contentId, title, showContentId, firstLineNum) >> ERRORS
            sortkey = sprintf ("(%s) (2) S%02dE%03d %s", showTitle, seasonNumber, episodeNumber,
                    showContentId)
        }
        # print "sortkey = " sortkey > "/dev/stderr"
        # Compose title
        title = sprintf ("%s, S%02dE%03d, %s", showTitle, seasonNumber, episodeNumber, title)
    }

    # Generate a link that will lead to the show on BritBox
    # https://www.britbox.com/us/movie/A_Queen_Is_Crowned_13551
    # https://www.britbox.com/us/movie/_13551
    #
    # https://www.britbox.com/us/show/All_Creatures_Great_and_Small_23737
    # https://www.britbox.com/us/show/_23737
    #
    # https://www.britbox.com/us/season/All_Creatures_Great_and_Small_S2_23752
    # https://www.britbox.com/us/season/_23752
    #
    # https://www.britbox.com/us/episode/All_Creatures_Great_and_Small_S2_E2_23764
    # https://www.britbox.com/us/episode/_23764
    showType_URL = contentType "/"
    sub (/tv_/,"",showType_URL)
    full_URL = "https://www.britbox.com/us/" showType_URL EntityId
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" title "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # A seasonless "show" should have blank rather than 0 seasons
    if (showType == "seasonless")
        numSeasons = ""
    # If an "episode" sortkey or fullTitle contains "S00E" delete the "S00" part
    sub (/S00E/,"E",sortkey)
    sub (/S00E/,"E",fullTitle)
    # Print everything except tv_seasons
    if (contentType != "tv_season")
        printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%06d\t%06d\n",
                sortkey, fullTitle, numSeasons, numEpisodes, duration, genre, year, rating, description,
                contentType, contentId, EntityId, showType, dateType, originalDate, showContentId,
                seasonContentId, seasonNumber, episodeNumber, firstLineNum, lastLineNum)
}

END {
    printf ("In getBBoxCatalogFromSitemap.awk\n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1 ? pluralEpisodes = "episode" : pluralEpisodes = "episodes"
    totalCredits == 1 ? pluralCredits = "credit" : pluralCredits = "credits"
    #
    printf ("    Processed %d %s, %d %s, %d %s, %d %s, %d %s\n", totalMovies, pluralMovies,
            totalShows, pluralShows, totalSeasons, pluralSeasons, totalEpisodes, pluralEpisodes,
            totalCredits, pluralCredits) > "/dev/stderr"

    if (missingEntityIds > 0 ) {
        missingEntityIds == 1 ? plural = "EntityId" : plural = "EntityIds"
        printf ("%8d missing %s in %s\n", missingEntityIds, plural, FILENAME) > "/dev/stderr"
    }

    if (missingShowContentIds > 0 ) {
        missingShowContentIds == 1 ? plural = "showContentId" : plural = "showContentIds"
        printf ("%8d missing %s in %s\n", missingShowContentIds, plural, FILENAME) > "/dev/stderr"
    }

    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf ("%8d %s revised in %s\n", revisedTitles, plural, FILENAME) > "/dev/stderr"
    }
}
