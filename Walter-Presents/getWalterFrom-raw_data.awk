# Grab fields from Walter Presents HTML files
# Title  Seasons  Episodes  Duration  Language Description

# Title  Seasons  Episodes  Duration  Genre  Country  Language  Rating  Description

# Title  Seasons  Episodes  Duration  Genre  Year  Rating  Description  Content_Type  Content_ID  Show_Type  Date_Type  Season_ID  Sn_#  Ep_#

/^https:/ {
    totalShows += 1
    split ($0,fld,"\t")
    showURL = fld[1]
    # print "==> showURL = " showURL > "/dev/stderr"
    # Create shorter URL by removing https://
    shortURL = showURL
    sub (/.*pbs.org/,"pbs.org",shortURL)
    showTitle = fld[2]
    print showTitle >> RAW_TITLES
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    showLanguage = "English"
    next
}

/ with English subtitles/ {
    showLanguage = $(NF - 3)
}

/"description":/ {
    descriptionLinesFound++
    split ($0,fld,"\"")
    showDescription = fld[4]
    gsub (/&#x27;/,"'",showDescription)
    sub (/ with English subtitles/,"",showDescription)
    sub (/ From Walter Presents, in/," In",showDescription)
    # print showDescription
    next
}

/"genre":/ {
    genreLinesFound++
    split ($0,fld,"\"")
    showGenre = fld[4]
    next
}

/data-title=/ {
    split ($0,fld,"\"")
    episodeTitle = fld[2]
    sub (/&amp;/,"\\&",episodeTitle)
    next
}

/data-video-type="clip"/,/Clip:/ {
    next
}

/data-video-type="preview"/,/Preview:/ {
    next
}

/data-video-slug=/ {
    split ($0,fld,"\"")
    episodeURL = sprintf ("https://www.pbs.org/video/%s/",fld[2])
    episodeLink = \
        "=HYPERLINK(\"" episodeURL "\";\"" showTitle ", " episodeTitle "\")"
    next
}

# Durations
/ S.[0-9]* Ep[0-9]* \| / \
    || / Ep[0-9]* \| / \
    || /                                    Special \| / \
    || / [0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| / {
    durationLinesFound++
    split ($0,fld,"|")
    # print fld[2]
    numFields = split (fld[2],tm," ")
    # Initialize fields to 0 in case any are missing
    secs = mins = hrs = 0
    for (i = 1; i <= numFields; ++i) {
        if (tm[i] ~ /s/) {
            sub (/s/, "", tm[i])
            secs = tm[i]
        }
        if (tm[i] ~ /m/) {
            sub (/m/, "", tm[i])
            mins = tm[i]
        }
        if (tm[i] ~ /h/) {
            sub (/h/, "", tm[i])
            hrs = tm[i]
        }
    }

    showSecs += secs
    showMins += mins + int(showSecs / 60)
    showHrs += hrs + int(showMins / 60)
    showSecs %= 60; showMins %= 60

    totalTime[3] += secs
    totalTime[2] += mins + int(totalTime[3] / 60)
    totalTime[1] += hrs + int(totalTime[2] / 60)
    totalTime[3] %= 60; totalTime[2] %= 60

    # Wrap up episode
    episodeDuration = sprintf ("%02d:%02d:%02d",hrs,mins,secs)
    episodeString = sprintf ("%s\t\t\t%s\n", episodeLink, episodeDuration)
    episodeList = episodeList episodeString
    episodeLink = ""
    episodeDuration = ""
    episodeString = ""
}

# Special episodes
/                                    Special \| / {
    episodeLinesFound++
    totalEpisodes++
    next
}

# Episodes from shows with more than one season
/ S.[0-9]* Ep[0-9]* \| / {
    sub (/^ */, "")
    split ($0,fld," ")
    seasonsArray[fld[1]]++
    showSeasons = length(seasonsArray)
    episodeLinesFound++
    totalEpisodes++
    next
}

# Episodes from shows with only one season
/ Ep[0-9]* \| / {
    showSeasons = 1
    episodeLinesFound++
    totalEpisodes++
    next
}

# Episodes from shows that use dates instead of seasons
/[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| / {
    sub (/^ */, "")
    sub (/ .*/, "")
    split ($0,fld,"/")
    seasonsArray[fld[3]]++
    showSeasons = length(seasonsArray)
    episodeLinesFound++
    totalEpisodes++
    next
}

/-- start medium-rectangle-half-page --/ {
    # print showTitle > "/dev/stderr"
    if (episodeLinesFound == 0) {
        printf ("==> No episodes found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (episodeLinesFound == 1) {
        printf ("==> Only one episode: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (descriptionLinesFound == 0) {
        printf ("==> No description found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (genreLinesFound == 0) {
        printf ("==> No genre found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }
    if (durationLinesFound == 0) {
        printf ("==> No durations found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    }

    # Fix any known issues
    if (showTitle == "La Otra Mirada" && showLanguage != "Spanish") {
        printf ("==> Setting '%s' language to Spanish\n", showTitle) >> ERRORS
        showLanguage = "Spanish"
    }
    if (showTitle == "Superabundant" && showGenre == "") {
        printf ("==> Setting '%s' genre to Food\n", showTitle) >> ERRORS
        showGenre = "Food"
    }

    # Wrap up show
    showDurationText = sprintf ("%02dh %02dm", showHrs, showMins)
    totalSeasons += showSeasons
    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", showLink, showSeasons, \
            episodeLinesFound, showDurationText, showGenre, showLanguage, \
            showDescription)
    printf ("%s\t%s\t%s\t\t%s\t%s\t%s\n", showLink, showSeasons, \
            episodeLinesFound, showGenre, showLanguage, \
            showDescriListption) >> LONG_SPREADSHEET
    printf ("%s", episodeList) >> LONG_SPREADSHEET
    # Make sure there is no carryover
    showURL = ""
    showTitle = ""
    showLink = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    showSeasons = 0
    showDuration = ""
    showDescription = ""
    showGenre = ""
    showLanguage = ""
    delete seasonsArray
    #
    episodeList = ""
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound  = 0
    genreLinesFound = 0
    durationLinesFound = 0
}

END {
    printf ("%02dh %02dm\n", totalTime[1], totalTime[2]) >> DURATION  
    printf ("In getWalterFrom-raw_data.awk\n") > "/dev/stderr"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1 ? pluralEpisodes = "episode" : pluralEpisodes = "episodes"
    printf ("    Processed %d %s, %d %s, %d %s\n", totalShows, pluralShows,
        totalSeasons, pluralSeasons, totalEpisodes, pluralEpisodes) > "/dev/stderr"
}
