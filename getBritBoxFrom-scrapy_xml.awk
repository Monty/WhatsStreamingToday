BEGIN {
    FS="[<>]"
}

/^<item>/ {
    sub (/^<item>/,"")
    sub (/<\/item>$/,"")
}

/<value>/ {
    gsub (/<value>/,"")
    gsub (/<\/value>/,"")
}

# <URL>/us/episode/Vera_S3_E1_13502</URL><Title>Vera</Title><Subtitle>Season 3, Castles in The Air</Subtitle>\
# <Duration>88 min</Duration><Year>2013</Year><Rating>TV-MA</Rating>
/\/us\/episode\// {
    episodeURL = $3
    seriesTitle = $7
    episodeTitle = $11
    episodeDuration = $15
    episodeYear = $19
    episodeRating = $23
    episodeDescription = $27

    nfields = split (episodeURL,fld,"_")
    seasonNumber = fld[nfields - 2]
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[nfields - 1]
    sub (/E/,"",episodeNumber)

    if (episodeNumber != "") {
        printf \
            ("%s S%02dE%02d\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, S%02dE%02d, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             seriesTitle, seasonNumber, episodeNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber, \
             episodeTitle, episodeDuration, episodeYear, episodeRating, episodeDescription)
    }
}

# <URL>/us/season/Vera_S8_15720</URL><Title>Vera</Title><SeasonNumber>8</SeasonNumber>\
# <Year>2018</Year><NumEpisodes>4</NumEpisodes>
/\/us\/season\// {
    seasonURL = $3
    seriesTitle = $7
    seasonTitle = $11
    seasonYear = $15
    seasonEpisodes = $19

    nfields = split (seasonURL,fld,"_")
    seasonNumber = fld[nfields - 1]
    sub (/S/,"",seasonNumber)

    if (seasonNumber != "") {
        printf \
            ("%s S%02d\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, Season %d\"\)\t%s\t\t%s\t%s\t%s\n", \
             seriesTitle, seasonNumber, seasonURL, seriesTitle, seasonNumber, \
             seasonEpisodes, seasonYear, seasonRating, seasonDescription)
    }
}
