BEGIN {
    FS="[<>]"
}

# Eliminate unneeded constant fields
/^<item>/ {
    sub (/^<item>/,"")
    sub (/<\/item>$/,"")
    gsub (/<value>/,"")
    gsub (/<\/value>/,"")
}

/\/us\// {
    URL = $3
    showTitle = $7
    subtitle = $11

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }
}

# <URL>/us/episode/Vera_S3_E1_13502</URL><Title>Vera</Title><Subtitle>Season 3, Castles in The Air</Subtitle>\
# <Duration>88 min</Duration><Year>2013</Year><Rating>TV-MA</Rating>
/\/us\/episode\// {
    episodeDuration = $15
    episodeYear = $19
    episodeRating = $23
    episodeDescription = $27

    nfields = split (URL,fld,"_")
    seasonNumber = fld[nfields - 2]
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[nfields - 1]
    sub (/E/,"",episodeNumber)

    # Get rid of perfunctory "Season <n>, " from episode title
    episodePrefix = "Season " seasonNumber ", "
    sub (episodePrefix, "", subtitle)

    if (episodeNumber != "") {
        printf \
            ("%s S%02dE%02d\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, S%02dE%02d, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             showTitle, seasonNumber, episodeNumber, URL, showTitle, seasonNumber, episodeNumber, \
             subtitle, episodeDuration, episodeYear, episodeRating, episodeDescription)
    }
}

# <URL>/us/season/Vera_S8_15720</URL><Title>Vera</Title><SeasonNumber>8</SeasonNumber>\
# <Year>2018</Year><NumEpisodes>4</NumEpisodes>
/\/us\/season\// {
    seasonYear = $15
    seasonEpisodes = $19

    nfields = split (URL,fld,"_")
    seasonNumber = fld[nfields - 1]
    sub (/S/,"",seasonNumber)

    if (seasonNumber != "") {
        printf \
            ("%s S%02d\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, Season %d\"\)\t%s\t\t%s\t%s\t%s\n", \
             showTitle, seasonNumber, URL, showTitle, seasonNumber, \
             seasonEpisodes, seasonYear, seasonRating, seasonDescription)
    }
}
