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

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }
}

# <URL>/us/movie/70_Glorious_Years_13550</URL><Title>70 Glorious Years</Title>\
# <Subtitle></Subtitle><Duration>60 min</Duration><Year>1996</Year><Rating>TV-PG</Rating>
/\/us\/movie\// {
    movieDuration = $15
    movieYear = $19
    movieRating = $23
    movieDescription = $27

    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("M%05d", fld[nflds])
        printf \
            ("%s %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s\"\)\t\t\t%s\t%s\t%s\n", \
             showTitle, sortkey, URL, showTitle, sortkey, \
             episodeYear, episodeRating, episodeDescription)
    }
}


# <URL>/us/episode/Vera_S3_E1_13502</URL><Title>Vera</Title><Subtitle>Season 3, Castles in The Air</Subtitle>\
# <Duration>88 min</Duration><Year>2013</Year><Rating>TV-MA</Rating>
/\/us\/episode\// {
    episodeTitle = $11
    episodeDuration = $15
    episodeYear = $19
    episodeRating = $23
    episodeDescription = $27

    # Extract season & episode from URL
    nflds = split (URL,fld,"_")
    seasonNumber = fld[nflds - 2]
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[nflds - 1]
    sub (/E/,"",episodeNumber)
    sortkey = sprintf ("S%02dE%02d", seasonNumber, episodeNumber)

    if (URL ~ /_Special_[[:digit:]]*$/)
        sortkey = sprintf ("X%05d", fld[nflds])

    # Convert minutes to HMS
    secs = 0
    mins = episodeDuration % 60
    hrs = int(episodeDuration / 60) 
    episode_HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)

    # Get rid of perfunctory "Season <n>, " from episode title
    episodePrefix = "Season " seasonNumber ", "
    sub (episodePrefix, "", episodeTitle)

    if (episodeNumber != "") {
        printf \
            ("%s %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             showTitle, sortkey, URL, showTitle, sortkey, \
             episodeTitle, episode_HMS, episodeYear, episodeRating, episodeDescription)
    }
}

# <URL>/us/season/Vera_S8_15720</URL><Title>Vera</Title><SeasonNumber>8</SeasonNumber>\
# <Year>2018</Year><NumEpisodes>4</NumEpisodes>
/\/us\/season\// {
    seasonNumber = $11
    seasonYear = $15
    seasonEpisodes = $19

    if (seasonNumber != "") {
        printf \
            ("%s S%02d\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, Season %d\"\)\t%s\t\t%s\t%s\t%s\n", \
                 showTitle, seasonNumber, URL, showTitle, seasonNumber, \
                 seasonEpisodes, seasonYear, seasonRating, seasonDescription)
    }
}
