# Grab fields from Walter Presents HTML files
# 
# Title  Seasons  Episodes  Duration  Genre  Language  Rating  Description

/^https:/ {
    totalShows += 1
    split ($0,fld,"\t")
    showURL = fld[1]
    # print "==> showURL = " showURL > "/dev/stderr"
    # Create shorter URL by removing https://
    shortURL = showURL
    sub (/.*pbs.org/,"pbs.org",shortURL)
    showTitle = fld[2]
    if (shortURL ~ /before-we-die-uk/) {
        showTitle = "Before We Die (UK)"
    }
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
    gsub (/&quot;/,"\"",showDescription)
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

/data-video-type=/ {
    episodeType = "X"
    split ($0,fld,"\"")
    if (fld[2] == "episode")
        episodeType = "E"
    next
}

/data-video-slug=/ {
    split ($0,fld,"\"")
    episodeID = sprintf ("/%s/",fld[2])
    episodeURL = sprintf ("https://www.pbs.org/video%s",episodeID)
    next
}

# Special episodes
/^                                    Special \| / {
    specialEpisodeNumber++
    episodeLinesFound++
    totalEpisodes++
}

# Episodes from shows with only one season
/^ *Ep[0-9]* \| / {
    sub (/^ */, "")
    split ($0,fld," ")
    episodeNumber = fld[1]
    sub (/Ep/, "", episodeNumber)
    seasonNumber = 1
    showSeasons = 1
    episodeLinesFound++
    totalEpisodes++
}

# Episodes from shows with more than one season
/^ *S.[0-9]* Ep[0-9]* \| / {
    sub (/^ */, "")
    split ($0,fld," ")
    seasonNumber = fld[1]
    seasonsArray[seasonNumber]++
    showSeasons = length(seasonsArray)
    sub (/S/,"",seasonNumber)
    episodeNumber = fld[2]
    sub (/Ep/, "", episodeNumber)
    episodeLinesFound++
    totalEpisodes++
}

# Episodes from shows that use dates instead of seasons
/^ *[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| / {
    sub (/^ */, "")
    split ($0,fld,"/")
    seasonNumber = fld[3]
    sub (/ .*/, "",seasonNumber)
    seasonsArray[seasonNumber]++
    showSeasons = length(seasonsArray)
    episodeArray[seasonNumber]++
    episodeNumber = episodeArray[seasonNumber]
    episodeLinesFound++
    totalEpisodes++
}

# Wrap up episode
# Leading spaces have been deleted in episode logic
/^S.[0-9]* Ep[0-9]* \| / \
      || /^Ep[0-9]* \| / \
      || /^                                    Special \| / \
      || /^[0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| / {
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

    episodeDuration = sprintf ("%02d:%02d:%02d",hrs,mins,secs)
    if (episodeType == "X")
        episodeNumber = specialEpisodeNumber
    # Special case for Central Florida Roadtrip season 2
    if (episodeNumber + 0 >= 18000)
        episodeNumber = episodeNumber - 18000
    # Special case for episodeNumbers that include season number
    if (episodeNumber + 0 >= 100)
        episodeNumber = episodeNumber - seasonNumber * 100
    episodeLink = sprintf ("=HYPERLINK(\"%s\";\"%s, S%02d%s%02d, %s\")",
        episodeURL, showTitle, seasonNumber, episodeType, episodeNumber,
        episodeTitle)
    printf ("%s\t\t\t%s\n", episodeLink, episodeDuration) >> LONG_SPREADSHEET
    printf ("%s\t%s\n", episodeID, showTitle) >> EPISODE_IDS

    episodeTitle = ""
    episodeType = ""
    episodeURL = ""
    episodeDuration = ""
    episodeLink = ""
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
    if (showSeasons == 0) {
        printf ("==> No seasons found: %s '%s'\n", \
                shortURL, showTitle) >> ERRORS
    } else {
        printf ("%s\t%s\t%s\t%s\t%s\t%s\t\t%s\n", showLink, showSeasons, \
             episodeLinesFound, showDurationText, showGenre, showLanguage, \
             showDescription)
        printf ("%s\t%s\t%s\t\t%s\t%s\t\t%s\n", showLink, showSeasons, \
             episodeLinesFound, showGenre, showLanguage, \
             showDescription) >> LONG_SPREADSHEET
    }
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
    delete episodeArray
    #
    episodeNumber = 0
    specialEpisodeNumber = 0
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound  = 0
    genreLinesFound = 0
    durationLinesFound = 0
}

END {
    printf ("%02dh %02dm\n", totalTime[1], totalTime[2]) > DURATION
    printf ("In getWalterFrom-raw_data.awk\n") > "/dev/stderr"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1 ? pluralEpisodes = "episode" : pluralEpisodes = "episodes"
    printf ("    Processed %d %s, %d %s, %d %s\n", totalShows, pluralShows,
        totalSeasons, pluralSeasons, totalEpisodes, pluralEpisodes) > "/dev/stderr"
}
