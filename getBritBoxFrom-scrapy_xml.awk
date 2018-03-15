BEGIN {
    FS="[<>]"
}

# Eliminate unneeded constant fields from XML
/^<item>/ {
    sub (/^<item>/,"")
    sub (/<\/item>$/,"")
    gsub (/<value>/,"")
    gsub (/<\/value>/,"")
}

# if needed for debugging record placment, replace "/nosuchrecord/" below
/nosuchrecord/ {
    print ""
    print NR " - " $0
    for ( i = 1; i <= NF; i++ ) {
        if ($i ~ /\/us\// )
            print "field " i " = " $i
    }
}

# Example input lines
#
# <URL>/us/movie/70_Glorious_Years_13550</URL><Title>70 Glorious Years</Title><Subtitle></Subtitle>\
# <Duration>60</Duration><Year>1996</Year><Rating>TV-PG</Rating>
#
# <URL>/us/episode/Vera_S3_E1_13502</URL><Title>Vera</Title><Subtitle>Season 3, Castles in The Air</Subtitle>\
# <Duration>88 min</Duration><Year>2013</Year><Rating>TV-MA</Rating>
#
# <URL>/us/season/Vera_S8_15720</URL><Title>Vera</Title><SeasonNumber>8</SeasonNumber>\
# <Year>2018</Year><NumEpisodes>4</NumEpisodes>

/^<URL>\/us\// {
    URL = $3
    showTitle = $7

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }
}

/^<URL>\/us\/episode\/|^<URL>\/us\/movie\// {
    Title = $11
    Duration = $15
    Year = $19
    Rating = $23
    Description = $27

    # Convert duration from minutes to HMS
    secs = 0
    mins = Duration % 60
    hrs = int(Duration / 60)
    HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
}

/^<URL>\/us\/movie\// {
    # Extract movie sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("M%05d", fld[nflds])
        printf \
            ("%s %s - mv\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             showTitle, sortkey, URL, showTitle, sortkey, \
             Title, HMS, Year, Rating, Description)
    }
}


/^<URL>\/us\/episode\// {
    # Extract episode sortkey from URL
    nflds = split (URL,fld,"_")
    seasonNumber = fld[nflds - 2]
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[nflds - 1]
    sub (/E/,"",episodeNumber)
    sortkey = sprintf ("S%02dE%02d", seasonNumber, episodeNumber)

    # Use X plus shownumber as sortkey for specials
    if (URL ~ /_Special_[[:digit:]]*$/)
        sortkey = sprintf ("X%05d", fld[nflds])

    # Get rid of perfunctory "Season <n>, " from episode title
    episodePrefix = "^Season " seasonNumber ", "
    sub (episodePrefix, "", Title)

    if (episodeNumber != "") {
        printf \
            ("%s %s - ep\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             showTitle, sortkey, URL, showTitle, sortkey, \
             Title, HMS, Year, Rating, Description)
    }
}

/^<URL>\/us\/season\// {
    seasonNumber = $11
    seasonYear = $15
    seasonEpisodes = $19
    seasonDescription = $23

    if (seasonNumber != "") {
        printf \
            ("%s S%02d - sn\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, Season %d\"\)\t%s\t\t%s\t%s\t%s\n", \
                 showTitle, seasonNumber, URL, showTitle, seasonNumber, \
                 seasonEpisodes, seasonYear, seasonRating, seasonDescription)
    }
}
