# Broduce a raw data spreadsheet of fields in BritBox Catalog --  apple_catalogue_feed.xml

# INVOCATION
#   awk -v ERROR_FILE=$ERROR_FILE -f getBBoxCatalogFrom-sitemap.awk $SITEMAP_FILE >$CATALOG_SPREADSHEET

# Field numbers
#     1 Sortkey       2 Title           3 Seasons          4 Episodes      5 Duration     6 Year
#     7 Rating        8 Description     9 Content_Type    10 Content_ID   11 Entity_ID   12 Genre
#    13 Show_Type    14 Date_Type      15 Original_Date   16 Show_ID      17 Season_ID   18 Sn_#
#    19 Ep_#         20 1st_#          21 Last_#

BEGIN {
    # Print header
    printf ("Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear\tRating\tDescription\t")
    printf ("Content_Type\tContent_ID\tEntity_ID\tGenre\tShow_Type\tDate_Type\tOriginal_Date\t")
    printf ("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")

    # For debugging variations in seasons and episodes format
    str = "date +%y%m%d.%H%M%S"
    str | getline longDate
    close str
}

# Don't process credits
/<credit role=/,/<\/credit>/ {
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
    # print "contentType = " contentType  > "/dev/stderr"
    # print "contentId = " contentId  > "/dev/stderr"
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
    numSeasons = 101
    numEpisodes = 202
}

# Grab title
# <title locale="en-US">Frequent Flyers</title>
/<title locale="en-US">/ {
    split ($0,fld,"[<>]")
    title = fld[3]
    # print "title = " title  > "/dev/stderr"
}

# Grab genre
# <genre>drama</genre>
/<genre>/ {
    split ($0,fld,"[<>]")
    genre = fld[3]
    # print "genre = " genre  > "/dev/stderr"
}

# Grab description
# <description>Set in the beautiful Yorkshire Dales, ...word.</description>
/<description>/ {
    split ($0,fld,"[<>]")
    description = fld[3]
    # print "description = " description  > "/dev/stderr"
}

# Grab rating
# <rating systemCode="us-tv">TV-PG</rating>
/<rating systemCode=/ {
    split ($0,fld,"[<>]")
    rating = fld[3]
    # print "rating = " rating  > "/dev/stderr"
}

# Grab type
# <type>series</type>
/<type>/ {
    split ($0,fld,"[<>]")
    showType = fld[3]
    # print "showType = " showType  > "/dev/stderr"
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
    # print "dateType = " dateType  > "/dev/stderr"
    # print "originalDate = " originalDate  > "/dev/stderr"
    # print "year = " year  > "/dev/stderr"
}

# Grab showContentId
# <showContentId>b008yjd9</showContentId>
/<showContentId>/ {
    split ($0,fld,"[<>]")
    showContentId = fld[3]
    # print "showContentId = " showContentId  > "/dev/stderr"
}

# Grab seasonContentId
# <seasonContentId>p0318ps9</seasonContentId>
/<seasonContentId>/ {
    split ($0,fld,"[<>]")
    seasonContentId = fld[3]
    # print "seasonContentId = " seasonContentId  > "/dev/stderr"
}

# Grab seasonNumber
# <seasonNumber>1</seasonNumber>
/<seasonNumber>/ {
    split ($0,fld,"[<>]")
    seasonNumber = fld[3]
    # print "seasonNumber = " seasonNumber  > "/dev/stderr"
}

# Grab episodeNumber
# <episodeNumber>10</episodeNumber>
/<episodeNumber>/ {
    split ($0,fld,"[<>]")
    episodeNumber = fld[3]
    # print "episodeNumber = " episodeNumber  > "/dev/stderr"
}

# Grab EntityId from artwork
# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;jpg&apos;&amp;Quality=45&amp;ImageId=&apos;176236&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;16103&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
/<artwork url=.*EntityId=&apos;/ {
    sub (/.*EntityId=&apos;/,"")
    sub (/&apos.*/,"")
    EntityId = "_" $0
    # print "EntityId = " EntityId  > "/dev/stderr"
}

# Do any special end of item processing, then print raw data spreadsheet row
/<\/item>/ {
    lastLineNum = NR
    # "Porridge" needs to be revised to avoid duplicate names
    if (title == "Porridge") {
        if (EntityId == "_9509") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Porridge (1974-1977)'\n", title) >> ERROR_FILE
            title = "Porridge (1974-1977)"
        } else if (EntityId == "_14747") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Porridge (2016-2017)'\n", title) >> ERROR_FILE
            title = "Porridge (2016-2017)"
        }
        # print "==> title = " title  > "/dev/stderr"
        # print "==> contentId = " contentId  > "/dev/stderr"
        # print "==> EntityId = " EntityId  > "/dev/stderr"
        # print "---"  > "/dev/stderr"
    }

    # "A Midsummer Night's Dream" needs to be revised to avoid duplicate names
    if (title == "A Midsummer Night's Dream") {
        if (EntityId == "_26179") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'A Midsummer Night\'s Dream (1981)'\n", title) >> ERROR_FILE
            title = "A Midsummer Night's Dream (1981)"
        } else if (EntityId == "_15999") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'A Midsummer Night\'s Dream (2016)'\n", title) >> ERROR_FILE
            title = "A Midsummer Night's Dream (2016)"
        }
        # print "==> title = " title  > "/dev/stderr"
        # print "==> EntityId = " EntityId  > "/dev/stderr"
    }

    # "Maigret" needs to be revised to clarify timeframe
    if (title ~ /^Maigret/ && contentType == "tv_show") {
        if (EntityId == "_15928") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Maigret (1992-1993)'\n", title) >> ERROR_FILE
            title = "Maigret (1992-1993)"
        } else if (EntityId == "_15974") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Maigret (2016–2017)'\n", title) >> ERROR_FILE
            title = "Maigret (2016–2017)"
        }
        # print "==> title = " title  > "/dev/stderr"
        # print "==> originalDate = " originalDate  > "/dev/stderr"
        # print "==> contentId = " contentId  > "/dev/stderr"
        # print "==> EntityId = " EntityId  > "/dev/stderr"
        # print "---"  > "/dev/stderr"
    }

    if (EntityId == "") {
        missingEntityIds += 1
        printf ("==> Missing EntityId for %s %s '%s' in show %s\n", contentType, contentId, title, \
                showContentId) >> ERROR_FILE
        # Add missing EntityId
        if (contentId == "p07gnw9f") {
            EntityId = "_23842"
            printf ("==> Added EntityId %s for %s %s '%s' in show %s\n", EntityId, contentType, contentId,
                    title, showContentId) >> ERROR_FILE
            # print "==> EntityId = " EntityId  > "/dev/stderr"
        }
    }

    if (contentType == "movie") {
        # Wish I didn't have to do this, but "movie" is too common to be in a key field
        contentType = "tv_movie"
        sortkey = sprintf ("%s (1) %s M%s", title, originalDate, EntityId)
        # print "movie sortkey = " sortkey  > "/dev/stderr"
    }

    if (contentType == "tv_show") {
        # print "\ntv_show" > "/dev/stderr"
        numShows += 1
        showArray[numShows] = contentId
        titleArray[numShows] = title
        sortkey = sprintf ("%s (1) S%s", title, EntityId)
        # print "sortkey = " sortkey > "/dev/stderr"
    }

    if (contentType == "tv_season") {
        # print "\ntv_season" > "/dev/stderr"
        for ( i = 1; i <= numShows; i++ ) {
            if (showArray[i] == showContentId) {
                showTitle = titleArray[i]
                break
            }
        }
        sortkey = sprintf ("%s (2) S%02d", showTitle, seasonNumber)
        # print "sortkey = " sortkey  > "/dev/stderr"
        # Compose title
    }

    if (contentType == "tv_episode") {
        # xxx
        # print "\ntv_episode" > "/dev/stderr"
        for ( i = 1; i <= numShows; i++ ) {
            if (showArray[i] == showContentId) {
                showTitle = titleArray[i]
                break
            }
        }
        # Need to check that showContentId was actually found
        if (showArray[i] != showContentId) {
            missingShowContentIds += 1
            printf ("==> Missing showContentId for %s %s '%s' in show %s\n", contentType, contentId, title, \
                showContentId) >> ERROR_FILE
        }
        sortkey = sprintf ("%s (2) S%02dE%03d %s", showTitle, seasonNumber, \
                episodeNumber, showContentId)
        # print "sortkey = " sortkey  > "/dev/stderr"
        # Compose title
    }
    
    # Copied from above to make it easier to coordinate printing fields
    # printf ("Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear\tRating\tDescription\t")
    # printf ("Content_Type\tContent_ID\tEntity_ID\tGenre\tShow_Type\tDate_Type\tOriginal_Date\t")
    # printf ("Show_ID\tSeason_ID\tSn_#\tEp_#\t1st_#\tLast_#\n")

    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%06d\t%06d\n", \
            sortkey, title, numSeasons, numEpisodes, duration, year, rating, description, \
            contentType, contentId, EntityId, genre, showType, dateType, originalDate, \
            showContentId, seasonContentId, seasonNumber, episodeNumber, firstLineNum, lastLineNum)
}

END {
    printf ("In getBBoxCatalogFrom-sitemap.awk\n") > "/dev/stderr"
    if (missingEntityIds > 0 ) {
        missingEntityIds == 1 ? field = "EntityId" : field = "EntityIds"
        printf ("    %2d missing %s in %s\n", missingEntityIds, field, FILENAME) > "/dev/stderr"
    }
    #
    if (missingShowContentIds > 0 ) {
        missingShowContentIds == 1 ? field = "showContentId" : field = "showContentIds"
        printf ("    %2d missing %s in %s\n", missingShowContentIds, field, FILENAME) > "/dev/stderr"
    }
    #
    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? field = "title" : field = "titles"
        printf ("    %2d %s revised in %s\n", revisedTitles, field, FILENAME) > "/dev/stderr"
    }
}
