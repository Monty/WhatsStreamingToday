# Broduce a raw data spreadsheet of fields in BritBox Catalog --  apple_catalogue_feed.xml

# INVOCATION
#   awk -v ERROR_FILE=$ERROR_FILE -f getBBoxCatalogFrom-sitemap.awk $SITEMAP_FILE >$CATALOG_SPREADSHEET

# Field numbers
#     1 Sortkey       2 Title           3 Seasons          4 Episodes      5 Duration     6 Year
#     7 Rating        8 Description     9 Content Type    10 Content ID   11 Entity ID   12 Genre
#    13 Show Type    14 Date Type      15 Original Date   16 Show ID      16 Season ID   13 Sn #   14 Ep #

BEGIN {
    # Print header
    printf ("Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear\tRating\tDescription\t")
    printf ("Content Type\tContent ID\tEntity ID\tGenre\tShow Type\tDate Type\tOriginal Date\t")
    printf ("Show ID\tSeason ID\tSn #\tEp #\n")
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
    split ($0,fld,"\"")
    contentType = fld[2]
    contentId = fld[4]
    # print "contentType = " contentType
    # print "contentId = " contentId
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
    numSeasons = 111
    numEpisodes = 222
}

# Grab title
# <title locale="en-US">Frequent Flyers</title>
/<title locale="en-US">/ {
    split ($0,fld,"[<>]")
    title = fld[3]
    # print "title = " title
}

# Grab genre
# <genre>drama</genre>
/<genre>/ {
    split ($0,fld,"[<>]")
    genre = fld[3]
    # print "genre = " genre
}

# Grab description
# <description>Set in the beautiful Yorkshire Dales, ...word.</description>
/<description>/ {
    split ($0,fld,"[<>]")
    description = fld[3]
    # print "description = " description
}

# Grab rating
# <rating systemCode="us-tv">TV-PG</rating>
/<rating systemCode=/ {
    split ($0,fld,"[<>]")
    rating = fld[3]
    # print "rating = " rating
}

# Grab type
# <type>series</type>
/<type>/ {
    split ($0,fld,"[<>]")
    showType = fld[3]
    # print "showType = " showType
}

# Grab duration
# <duration>3000</duration>
/<duration>/ {
    split ($0,fld,"[<>]")
    duration = fld[3]
    # print "duration = " duration
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
    # print "dateType = " dateType
    # print "originalDate = " originalDate
    # print "year = " year
}

# Grab showContentId
# <showContentId>b008yjd9</showContentId>
/<showContentId>/ {
    split ($0,fld,"[<>]")
    showContentId = fld[3]
    # print "showContentId = " showContentId
}

# Grab seasonContentId
# <seasonContentId>p0318ps9</seasonContentId>
/<seasonContentId>/ {
    split ($0,fld,"[<>]")
    seasonContentId = fld[3]
    # print "seasonContentId = " seasonContentId
}

# Grab seasonNumber
# <seasonNumber>1</seasonNumber>
/<seasonNumber>/ {
    split ($0,fld,"[<>]")
    seasonNumber = fld[3]
    # print "seasonNumber = " seasonNumber
}

# Grab episodeNumber
# <episodeNumber>10</episodeNumber>
/<episodeNumber>/ {
    split ($0,fld,"[<>]")
    episodeNumber = fld[3]
    # print "episodeNumber = " episodeNumber
}

# Grab EntityId from artwork
# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;jpg&apos;&amp;Quality=45&amp;ImageId=&apos;176236&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;16103&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
/<artwork url=.*EntityId=&apos;/ {
    sub (/.*EntityId=&apos;/,"")
    sub (/&apos.*/,"")
    EntityId = "_" $0
    # print "EntityId = " EntityId
    next
}

# Do any special end of item processing, then print raw data spreadsheet row
/<\/item>/ {
    if (title == "Shallow Grave") {
        EntityId = "_23576"
        # print "==> EntityId = " EntityId
    }

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
        # print "==> title = " title
        # print "==> EntityId = " EntityId
    }

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
        # print "==> title = " title
        # print "==> EntityId = " EntityId
    }

    if (contentId == "p07gnw9f") {
        EntityId = "_23842"
        # print "==> EntityId = " EntityId
    }

    if (contentType == "movie") {
        sortkey = sprintf ("%s (1) %s M%s", title, originalDate, EntityId)
    }

    if (contentType == "tv_show") {
        showTitle = title
        sortkey = sprintf ("%s (1) S%s", title, EntityId)
    }

    if (contentType == "tv_season") {
        sortkey = sprintf ("%s (2) S%02d", showTitle, seasonNumber)
    }

    if (contentType == "tv_episode") {
        sortkey = sprintf ("%s (2) S%02dE%03d %s", showTitle, seasonNumber, \
                episodeNumber, showContentId)
    }
    
    # Copied from printing header to make it easier to coordinate arranging fields
    # printf ("Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear(s)\tRating\tDescription\t")
    # printf ("Content Type\tContent ID\tEntity ID\tGenre\tShow Type\tDate Type\tOriginal Date\t")
    # printf ("Show ID\tSeason ID\tSn #\tEp #\n")

    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
            sortkey, title, numSeasons, numEpisodes, duration, year, rating, description, \
            contentType, contentId, EntityId, genre, showType, dateType, originalDate, \
            showContentId, seasonContentId, seasonNumber, episodeNumber)
}

# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;jpg&apos;&amp;Quality=45&amp;ImageId=&apos;176236&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;16103&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
# https://www.britbox.com/us/movie/300_Years_of_French_and_Saunders_16103
/<item contentType="movie"/,/<\/item>/ {
    # print
}

END {
    printf ("In getBBoxCatalogFrom-sitemap.awk\n") > "/dev/stderr"
    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? field = "title" : field = "titles"
        printf ("    %2d %s revised in %s\n", revisedTitles, field, FILENAME) > "/dev/stderr"
    }
}
