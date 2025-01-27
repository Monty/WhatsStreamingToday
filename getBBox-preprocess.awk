# Extract meaningful fields from raw BBox HTML files

# <hero-actions showid="16103" contentid="16103" path="/movie/300_Years_of_French_and_Saunders_p05wv7gy" :item="{"type":"movie","advisoryText":"","copyright":"","distributor":"BBC","description":"Comedy dream team Dawn French and Jennifer Saunders reunite for thefirst time in ten years for a thirtieth-anniversary show bursting mirth,mayhem, And wigs. Lots and lots of wigs.","customMetadata":[],"genrePaths":["/movies/genres/Comedy"],"credits":[{"role":"actor","name":"Dawn French","path":"/name/Dawn_French","character":"Variouscharacters"},{"role":"actor","name":"Jennifer Saunders","path":"/name/Jennifer_Saunders","character":"Various characters"}

# Skip empty lines
/^$/ { next }

# ,"contextualTitle":"300 Years of French and Saunders","
/,"contextualTitle":"/ {
    if (match($0, /,"contextualTitle":"[^"]+","/)) {
        title = substr($0, RSTART + 1, RLENGTH - 3)
        # print "title = " title > "/dev/stderr"
        split(title, fld, "\"")
        print "title: " fld[4]
    }
}

# ,"description":"Comedy ... lots of wigs.","
/,"description":"/ {
    if (match($0, /,"description":"([^"]|\\")*","/)) {
        description = substr($0, RSTART + 16, RLENGTH - 19)
        # print "description = " description > "/dev/stderr"
        print "description: " description
    }
}

# ,"path":"/movie/300_Years_of_French_and_Saunders_p05wv7gy","
/,"path":"\/movie\// {
    if (match($0, /,"path":"\/movie\/[^"]+","/)) {
        partial_URL = substr($0, RSTART + 1, RLENGTH - 3)
        # print "partial_URL = " partial_URL > "/dev/stderr"
        split(partial_URL, fld, "\"")
        print "full_URL: https://www.britbox.com/us" fld[4]
    }
}

# "type":"movie","
/^"type":"/ {
    if (match($0, /^"type":"[^"]+","/)) {
        itemType = substr($0, RSTART, RLENGTH - 2)
        # print "itemType = " itemType > "/dev/stderr"
        split(itemType, fld, "\"")
        print "itemType: " fld[4]
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

# ,"customId":"p05wv7gy","
/,"customId":"/ {
    if (match($0, /,"customId":"[^"]+","/)) {
        customId = substr($0, RSTART + 1, RLENGTH - 3)
        # print "customId = " customId > "/dev/stderr"
        split(customId, fld, "\"")
        print "customId: " fld[4]
    }
}

# ,"duration":2923,"
/,"duration":/ {
    if (match($0, /,"duration":[^"]+,"/)) {
        duration = substr($0, RSTART + 12, RLENGTH - 14)
        # print "duration = " duration > "/dev/stderr"
        print "duration: " duration
    }

    # Print "End of Movie" indicator
    print "--EOM--\n"
}
