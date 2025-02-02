# Extract meaningful fields from raw BBox HTML files
BEGIN { print "==> New File" }

# Skip empty lines
/^$/ { next }

# <meta property="og:title" content="63 Up" />
# <meta property="og:title" content="Grace" />
# <meta property="og:title" content="Macbeth (2018)" />
# Extract the show/movie title. It will always be the
# show/movie title, not the season or episode title.
/meta property="og:title/ {
    split($0, fld, "\"")
    showTitle = fld[4]
    # print "==> showTitle = " showTitle > "/dev/stderr"
    print "showTitle: " showTitle
    next
}

# <meta property="og:description" content="Comedy ... of wigs." />
# Extract the show/movie description. It will always be the
# show/movie description, not the season or episode description.
/<meta property="og:description" content="/ {
    sub(/<meta property="og:description" content="/, "")
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
    split(partial_URL, fld, "/")
    fileType = fld[3]
    # print "fileType = " fileType > "/dev/stderr"
    if (fileType == "movie") { print "--BOM--" }

    if (fileType == "show" || fileType == "season") { print "--BOS--" }

    print "full_URL: https://www.britbox.com" partial_URL

    fileName = fld[4]
    # print "fileName = " fileName > "/dev/stderr"
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

        if (fileType == "show" && itemType != "show") { next }

        if (fileType == "season" && itemType == "show") { next }

        if (itemType == "episode") { print "--BOE--" }

        # print "itemType = " itemType > "/dev/stderr"
        print "itemType: " itemType
    }
}

# ,"contextualTitle":"300 Years of French and Saunders","
# ,"contextualTitle":"Season 1","
# ,"contextualTitle":"1. Episode 1","
# Movies use showTitle not movieTitle
/,"contextualTitle":"/ && fileType != "movie" {
    if (match($0, /,"contextualTitle":"[^"]+","/)) {
        contextualTitle = substr($0, RSTART + 1, RLENGTH - 3)
        split(contextualTitle, fld, "\"")
        contextualTitle = fld[4]
        # printf("%sTitle = %s\n", itemType, contextualTitle) > "/dev/stderr"
        printf("%sTitle: %s\n", itemType, contextualTitle)
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
/,"shortDescription":"/ && fileType != "movie" {
    if (match($0, /,"shortDescription":"([^"]|\\")*","/)) {
        episodeDescription = substr($0, RSTART + 21, RLENGTH - 24)
        # print "episodeDescription = " episodeDescription > "/dev/stderr"
        print "episodeDescription: " episodeDescription
    }
}

# ,"genres":["Drama"],"
# ["/movies/genres/Comedy"]
# ["/tv/genres/Mystery"]
/\["\/movies\/genres\// || /\["\/tv\/genres\// {
    if (match($0, /\["\/(movies|tv)\/genres\/[^"]+"\]/)) {
        showGenre = substr($0, RSTART + 1, RLENGTH - 3)
        # print "showGenre = " showGenre > "/dev/stderr"
        split(showGenre, fld, "/")
        showGenre = fld[4]
        print "showGenre: " showGenre
    }
}

# ,"genres":["Drama"],"
/,"genres":\["/ && fileType != "movie" {
    if (match($0, /,"genres":\["[^"]*"\],/)) {
        episodeGenre = substr($0, RSTART, RLENGTH)
        split(episodeGenre, fld, "\"")
        episodeGenre = fld[4]
        # print "episodeGenre = " episodeGenre > "/dev/stderr"
        print "episodeGenre: " episodeGenre
    }
}

# {"role":"actor","name":"Victoria Graham","path":"/name/Victoria_Graham","character":"Newsreader"}
/\{"role":"/ {
    credits = $0

    while (match(credits, /\{"role":[^}]*\}/)) {
        castMember = substr(credits, RSTART + 1, RLENGTH - 2)
        # print "castMember = " castMember > "/dev/stderr"
        numFields = split(castMember, fld, "\"")
        person_role = fld[4]
        print "person_role: " person_role
        person_name = fld[8]
        print "person_name: " person_name
        person_URL = fld[12]
        print "person_URL: " person_URL
        character_name = fld[16]
        print "character_name: " character_name

        credits = substr(credits, RSTART + RLENGTH)
    }
}

# ,"seasons":{"id":"26113-seasons","path":"","size":1,"items"
# ,"seasons":{"id":"9509-seasons","path":"","size":3,"items"
# Get showID and numberOfSeasons
/,"seasons":\{"id":"/ {
    # Match everything from ,"seasons":{"id":" up to "items"
    if (match($0, /,"seasons":\{"id":"[0-9]+-seasons","size":[0-9]+,"items/)) {
        lastOfShow = substr($0, RSTART + 17, RLENGTH - 22)
        # print "lastOfShow = " lastOfShow > "/dev/stderr"
        split(lastOfShow, fld, "\"")
        showId2 = fld[2]
        sub(/-seasons/, "", showId2)
        # print "showId2: " showId2 > "/dev/stderr"
        print "showId2: " showId2
        numberOfSeasons = fld[5]
        sub(/:/, "", numberOfSeasons)
        sub(/,$/, "", numberOfSeasons)
        # print "numberOfSeasons: " numberOfSeasons > "/dev/stderr"
        print "numberOfSeasons: " numberOfSeasons
    }

    # Print "End of Show" indicator
    print "--EOS--\n"
}

# {"code":"TVPG-TV-14","name":"TV-14"}
/\{"code":"/ {
    if (match($0, /\{"code":"[^}]*\}/)) {
        rating = substr($0, RSTART + 1, RLENGTH - 3)
        # print "rating = " rating > "/dev/stderr"
        split(rating, fld, "\"")
        rating = fld[8]
        print "rating: " rating
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
        customId = fld[4]
        print "customId: " customId
    }

    if (itemType == "movie") {
        # Print "End of Movie" indicator
        print "--EOM--\n"
    }
    else if (itemType == "episode") {
        # Print "End of Episode" indicator
        print "--EOE--\n"
    }
}
