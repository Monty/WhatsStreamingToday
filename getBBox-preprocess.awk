# Extract meaningful fields from raw BBox HTML files

# <hero-actions showid="16103" contentid="16103" path="/movie/300_Years_of_French_and_Saunders_p05wv7gy" :item="{"type":"movie","advisoryText":"","copyright":"","distributor":"BBC","description":"Comedy dream team Dawn French and Jennifer Saunders reunite for thefirst time in ten years for a thirtieth-anniversary show bursting mirth,mayhem, And wigs. Lots and lots of wigs.","customMetadata":[],"genrePaths":["/movies/genres/Comedy"],"credits":[{"role":"actor","name":"Dawn French","path":"/name/Dawn_French","character":"Variouscharacters"},{"role":"actor","name":"Jennifer Saunders","path":"/name/Jennifer_Saunders","character":"Various characters"}

# Skip empty lines
/^$/ { next }

# <meta property="og:title" content="Grace" />
# <meta property="og:title" content="Macbeth (2018)" />
# Extract the show title
/meta property="og:title/ {
    split($0, fld, "\"")
    showTitleOG = fld[4]
    # print "==> showTitleOG = " showTitleOG > "/dev/stderr"
    print "showTitleOG: " showTitleOG
    next
}

# <meta name="description" content="Martin Freeman stars..." />
/<meta name="description" / {
    sub(/.*name="description" content="/, "")
    sub(/" \/>.*/, "")
    showDescription = $0
    # print "showDescription = " showDescription > "/dev/stderr"
    print "showDescription: " showDescription
    next
}

# <meta property="og:url" content="/us/movie/63_Up_p09668r0" />
# <meta property="og:url" content="/us/show/Grace_65424" />
# <meta property="og:url" content="/us/season/Grace_S1_10097327" />
/<meta property="og:url" content=/ {
    split($0, fld, "\"")
    partial_URL = fld[4]
    print "full_URL: https://www.britbox.com" partial_URL
    next
}

# "type":"movie","
# "type":"show","
# "type":"season","
# "type":"episode","
/^"type":"/ {
    if (match($0, /^"type":"[^"]+","/)) {
        itemType = substr($0, RSTART, RLENGTH - 2)
        split(itemType, fld, "\"")
        itemType = fld[4]
        # print "itemType = " itemType > "/dev/stderr"
        print "itemType: " itemType
    }
}

# ,"contextualTitle":"300 Years of French and Saunders","
# ,"contextualTitle":"Season 1","
# ,"contextualTitle":"1. Episode 1","
/,"contextualTitle":"/ {
    if (match($0, /,"contextualTitle":"[^"]+","/)) {
        contextualTitle = substr($0, RSTART + 1, RLENGTH - 3)
        split(contextualTitle, fld, "\"")
        contextualTitle = fld[4]
        # printf("%sTitle = %s\n", itemType, contextualTitle) > "/dev/stderr"
        printf("%sTitle: %s\n", itemType, contextualTitle)
    }
}

# ,"showTitle":"A Confession","
/,"showTitle":"/ {
    if (match($0, /,"showTitle":"[^"]+","/)) {
        showTitle2 = substr($0, RSTART + 1, RLENGTH - 3)
        split(showTitle2, fld, "\"")
        showTitle2 = fld[4]
        # print "showTitle2 = " showTitle2 > "/dev/stderr"
        print "showTitle2: " showTitle2
    }
}

# ,"showId":"26113","
/,"showId":"/ {
    if (match($0, /,"showId":"[^"]+","/)) {
        showId = substr($0, RSTART + 1, RLENGTH - 3)
        split(showId, fld, "\"")
        showId = fld[4]
        # print "showId = " showId > "/dev/stderr"
        print "showId: " showId
    }
}

# ,"seasonId":"26114","
/,"seasonId":"/ {
    if (match($0, /,"seasonId":"[^"]+","/)) {
        seasonId = substr($0, RSTART + 1, RLENGTH - 3)
        split(seasonId, fld, "\"")
        seasonId = fld[4]
        # print "seasonId = " seasonId > "/dev/stderr"
        print "seasonId: " seasonId
    }
}

# ,"shortDescription":"Martin Freeman stars ... Sian O’Callaghan.","
/,"shortDescription":"/ {
    if (match($0, /,"shortDescription":"([^"]|\\")*","/)) {
        description = substr($0, RSTART + 21, RLENGTH - 24)
        # print "description = " description > "/dev/stderr"
        print "description: " description
    }
}

# ,"genres":["Drama"],"
# ["/movies/genres/Comedy"]
/\["\/movies\/genres\// {
    if (match($0, /\["\/movies\/genres\/[^"]+"\]/)) {
        genre = substr($0, RSTART + 1, RLENGTH - 3)
        # print "genre = " genre > "/dev/stderr"
        split(genre, fld, "/")
        print "genre: " fld[4]
    }
}

# {"role":"actor","name":"Victoria Graham","path":"/name/Victoria_Graham","character":"Newsreader"}
/\{"role":"/ {
    credits = $0

    while (match(credits, /\{"role":[^}]*\}/)) {
        castMember = substr(credits, RSTART + 1, RLENGTH - 2)
        # print "castMember = " castMember > "/dev/stderr"
        numFields = split(castMember, fld, "\"")
        print "person_role: " fld[4]
        print "person_name: " fld[8]
        print "person_URL: " fld[12]
        print "character_name: " fld[16]

        credits = substr(credits, RSTART + RLENGTH)
    }
}

# {"code":"TVPG-TV-14","name":"TV-14"}
/\{"code":"/ {
    if (match($0, /\{"code":"[^}]*\}/)) {
        rating = substr($0, RSTART + 1, RLENGTH - 3)
        # print "rating = " rating > "/dev/stderr"
        split(rating, fld, "\"")
        print "rating: " fld[8]
    }
}

# ,"releaseYear":2017,"
/,"releaseYear":/ {
    if (match($0, /,"releaseYear":[^"]+,"/)) {
        releaseYear = substr($0, RSTART + 15, RLENGTH - 17)
        # print "releaseYear = " releaseYear > "/dev/stderr"
        print "releaseYear: " releaseYear
    }
}

# ,"seasonNumber":1,"
/,"seasonNumber":/ {
    if (match($0, /,"seasonNumber":[^"]+,"/)) {
        seasonNumber = substr($0, RSTART + 16, RLENGTH - 18)
        # print "seasonNumber = " seasonNumber > "/dev/stderr"
        print "seasonNumber: " seasonNumber
    }
}

# ,"episodeNumber":5,"
/,"episodeNumber":/ {
    if (match($0, /,"episodeNumber":[^"]+,"/)) {
        episodeNumber = substr($0, RSTART + 17, RLENGTH - 19)
        # print "episodeNumber = " episodeNumber > "/dev/stderr"
        print "episodeNumber: " episodeNumber
    }
}

# ,"episodeName":"Episode 5","
/,"episodeName":"/ {
    if (match($0, /,"episodeName":"[^"]+","/)) {
        episodeName = substr($0, RSTART + 1, RLENGTH - 3)
        split(episodeName, fld, "\"")
        episodeName = fld[4]
        # print "episodeName = " episodeName > "/dev/stderr"
        print "episodeName: " episodeName
    }
}

# ,"duration":2923,"
/,"duration":/ {
    if (match($0, /,"duration":[^"]+,"/)) {
        duration = substr($0, RSTART + 12, RLENGTH - 14)
        # print "duration = " duration > "/dev/stderr"
        print "duration: " duration
    }
}

# ,"customId":"p05wv7gy",
/,"customId":"/ {
    if (match($0, /,"customId":"[^"]+",/)) {
        customId = substr($0, RSTART + 1, RLENGTH - 3)
        # print "customId = " customId > "/dev/stderr"
        split(customId, fld, "\"")
        print "customId: " fld[4]
    }

    if (itemType == "movie") {
        # Print "End of Movie" indicator
        print "--EOM--\n"
    }
    else if (itemType == "episode") {
        # Print "End of Episode" indicator
        print "--EOE--\n"
    }
    else if (itemType == "season") {
        # Print "End of Season" indicator
        print "--EOS--\n"
    }
}
