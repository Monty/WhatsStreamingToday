/"title"/ {
    split ($0,fld,"\"")
    seriesTitle = fld[4]
    # print "title = " seriesTitle
}

/"episodeTitle"/ {
    split ($0,fld,"\"")
    episodeTitle = fld[4]
    # print "episodeTitle = " episodeTitle
}

/"url":/ {
    # "url": "/us/episode/New_Blood_S1_E4_9278",
    split ($0,fld,"\"")
    episodeURL = fld[4]
    nfields = split ($0,fld,"_")
    seasonNumber = fld[nfields - 2]
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[nfields - 1]
    sub (/E/,"",episodeNumber)
}

/"year":/ {
    split ($0,fld,"\"")
    episodeYear = fld[4]
    # print "year = " episodeYear
}

/"duration":/ {
    split ($0,fld,"\"")
    episodeDuration = fld[4]
    # print "duration = " episodeDuration
}

/"rating":/ {
    split ($0,fld,"\"")
    episodeRating = fld[4]
    # print "rating = " episodeRating
}

/"description":/ {
    split ($0,fld,"\"")
    episodeDescription = fld[4]
    # print "description = " episodeDescription
    if (episodeNumber != "") {
        printf \
            ("=HYPERLINK(\"https://www.britbox.com%s\";\"%s, S%02dE%02d, %s\"\)\t%s\t%s\t%s\t%s\n", \
             episodeURL, seriesTitle, seasonNumber, episodeNumber, \
             episodeTitle, episodeDuration, episodeYear, episodeRating, episodeDescription)
    }
}
