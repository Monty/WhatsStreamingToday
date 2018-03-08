BEGIN {
    FS = "\t"
}

/^\/us\/episode\// {
    episodeURL = $1
    seriesTitle = $2
    episodeTitle = $3
    episodeDuration = $4
    episodeYear = $5
    episodeRating = $6
    episodeDescription = $7

    nfields = split (episodeURL,fld,"_")
    seasonNumber = fld[nfields - 2]
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[nfields - 1]
    sub (/E/,"",episodeNumber)

    if (episodeNumber != "") {
        printf \
            ("=HYPERLINK(\"https://www.britbox.com%s\";\"%s, S%02dE%02d, %s\"\)\t%s\t%s\t%s\t%s\n", \
             episodeURL, seriesTitle, seasonNumber, episodeNumber, \
             episodeTitle, episodeDuration, episodeYear, episodeRating, episodeDescription)
    }
}

/^\/us\/season\// {
    seasonURL = $1
    seriesTitle = $2
    seasonTitle = $3
    seasonYear = $4
    seasonEpisodes = $5

    nfields = split (seasonURL,fld,"_")
    seasonNumber = fld[nfields - 1]
    sub (/S/,"",seasonNumber)

    if (seasonNumber != "") {
        printf \
            ("=HYPERLINK(\"https://www.britbox.com%s\";\"%s, S%02d, %s\"\)\t%s\t%s\t%s\t%s\n", \
             seasonURL, seriesTitle, seasonNumber, \
             seasonTitle, seasonEpisodes, seasonYear, seasonRating, seasonDescription)
    }
}
