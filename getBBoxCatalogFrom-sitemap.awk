# Broduce a raw data spreadsheet of fields in BritBox Catalog --  apple_catalogue_feed.xml

BEGIN {
    # Print header
    printf ("contentType\tcontentId\tpubDate\ttitle\tEntityId\n")
}

# Don't process credits
/<credit role=/,/<\/credit>/ {
    next
}

# Don't use Canadian ratings
/<rating systemCode="ca-tv">/ {
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
    pubDate = ""
    title = ""
    EntityId = ""
}

# Grab pubDate
# <pubDate>2020-06-05T21:51:00Z</pubDate>
/<pubDate>/ {
    split ($0,fld,"[<>]")
    pubDate = fld[3]
    sub (/T/," ",pubDate)
    sub (/Z/,"",pubDate)
    # print "pubDate = " pubDate
}
# Grab title
# <title locale="en-US">Frequent Flyers</title>
/<title locale="en-US">/ {
    split ($0,fld,"[<>]")
    title = fld[3]
    # print "title = " title
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
    printf ("%s\t%s\t%s\t%s\t%s\n", contentType, contentId, pubDate, title, EntityId)
}

# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;jpg&apos;&amp;Quality=45&amp;ImageId=&apos;176236&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;16103&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
# https://www.britbox.com/us/movie/300_Years_of_French_and_Saunders_16103
/<item contentType="movie"/,/<\/item>/ {
    # print
}

# <artwork url="https://us.britbox.com/isl/api/v1/dataservice/ResizeImage/$value?Format=&apos;png&apos;&amp;Quality=45&amp;ImageId=&apos;204656&apos;&amp;EntityType=&apos;Item&apos;&amp;EntityId=&apos;23740&apos;&amp;Width=1920&amp;Height=1080&amp;ResizeAction=&apos;fit&apos;" type="tile_artwork" />
# https://www.britbox.com/us/episode/The_Last_Furlong_23740
# https://www.britbox.com/us/episode/24_Hours_In_Police_Custody_23576