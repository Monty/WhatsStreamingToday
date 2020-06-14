# Broduce a raw data spreadsheet of fields in BritBox Catalog --  apple_catalogue_feed.xml

BEGIN {
    # Print header
    printf ("Content Type\tContent ID\tTitle\tEntity ID\tGenre\tRating\t")
    printf ("Show Type\tDuration\tDate Type\tOriginal Date\tShow ID\tSeason ID\t")
    printf ("Sn #\tEp #\tDescription\n")
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
    # print "dateType = " dateType
    # print "originalDate = " originalDate
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

# Print spacer between items
/<\/item>/ {
    if (title == "Shallow Grave") {
        EntityId = "_23576"
        # print "EntityId = " EntityId
    }
    if (contentId == "p07gnw9f") {
        EntityId = "_23842"
        # print "EntityId = " EntityId
    }
    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", contentType, contentId, \
            title, EntityId, genre, rating, showType, duration, dateType, originalDate, \
            showContentId, seasonContentId, seasonNumber, episodeNumber, description)
}

# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;jpg&apos;&amp;Quality=45&amp;ImageId=&apos;176236&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;16103&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
# https://www.britbox.com/us/movie/300_Years_of_French_and_Saunders_16103
/<item contentType="movie"/,/<\/item>/ {
    # print
}

# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;png&apos;&amp;Quality=45&amp;ImageId=&apos;204656&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;23740&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
# https://www.britbox.com/us/episode/The_Last_Furlong_23740
# https://www.britbox.com/us/episode/24_Hours_In_Police_Custody_23576
