# Produce a raw data spreadsheet from URLs found in https://watch.mhzchoice.com/sitemap.xml

# INVOCATION:
#    awk -v ERRORS=$ERRORS -v RAW_CREDITS=$RAW_CREDITS -v RAW_TITLES=$RAW_TITLES \
#        -f getMHzFromSitemap.awk >>$UNSORTED

# Field numbers
# 1 Title  2 Seasons  3 Episodes  4 Duration  5 Genre  6 Country  7 Language  8 Rating  9 Description

### Begin season processing

# Determine whether this is a page 2
#    <meta name="apple-itunes-app" content="app-id=1096194231, \
#        app-argument=https://mhzchoice.vhx.tv/detective-montalbano?page=2">
/<meta name="apple-itunes-app" content=".*?page=2">/ {
    page2 = "yes"
    next
}

# Season Title & Season URL
#    <form class="form"><input value="https://watch.mhzchoice.com/gasmamman/season:1" type="text" \
#        class="text text-center border-none site-background-color site-font-secondary-color" /></form>
# This returns incorrect values if page2 == "yes", but those values are never used
/<form class="form">/ {
    split ($0,fld,"\"")
    seasonURL = fld[4]
    shortSeasonURL = seasonURL
    sub (/.*watch/,"watch",shortSeasonURL)
    split (seasonURL,fld,":")
    seasonNumber = fld[3]
    seasonTitle = "Season " seasonNumber
    # print "==> seasonURL = " seasonURL > "/dev/stderr"
    # print "==> seasonNumber = " seasonNumber > "/dev/stderr"
    # print "==> seasonTitle = " seasonTitle > "/dev/stderr"
    next
}

# Season episodes
#    <h2 class="site-font-secondary-color site-font-primary-family content-label padding-top-medium \
#        grid-padding-right">
#      9 Episodes
#    </h2>
# Extract only the number of episodes, # but if this is page 2 skip to avoid double counting
/<h2 class=.*content-label/,/<\/h2>/ {
    sub (/^ */,"")
    if ($0 ~ / Episode/) {
        seasonEpisodes = $1
        next
    }
}

### Begin show processing

# Show Title
#    <title>Gasmamman - MHz Choice</title>
/<title>/ {
    split ($0,fld,"[<>]")
    showTitle = fld[3]
    sub (/ - MHz Choice/,"",showTitle)
    gsub (/&#x27;/,"'",showTitle)
    gsub (/&#39;/,"'",showTitle)
    print showTitle >> RAW_TITLES
    # print "==> showTitle = " showTitle > "/dev/stderr"
    next
}

# Show Descriptor
#    <meta name="description" content="DRAMA - CRIME | SWEDEN | SWEDISH WITH ENGLISH SUBTITLES | TV-14
#    Alexandra Rapaport stars as a suburban mom pulled into the criminal \
#        underworld to pay off her murdered husband’s debts.">
#
# There should be four header fields prior to the description
/<meta name="description" content="/,/">/ {
     # if we're on the first line of this block ...
    if ($0 ~ /name="description" content="/) {
        headerAdded = "no"
        sub (/.*name="description" content="/,"")
    }
    # If we find a header, clean it up and put it before the description
    if ($0 ~ /\|[ ]+TV[ ]*-/) {
        sub (/WITH ENGLISH SUBTITLES /,"")
        # Special case for Spitfire
        sub (/WITH ENGISH SUBTITLES /,"")
        sub (/[Ww]ith [Ee]nglish [Ss]ubtitles /,"")
        sub (/SCANDINAVIAN CRIME FICTION/,"Sweden")
        sub (/NON[-]*FICTION[ ]*-[ ]*DOCUMENTARY/,"Documentary")
        gsub (/[ ]*\|[ ]+/,"|")
        sub (/\r/,"")
        # Split out header fields
        numFields = split ($0,fld,"\|")
        # lowercase everything but the first character in all fields but the last
        for (i = 1; i < numFields; ++i) {
            fld[i] = substr(fld[i],1,1) tolower(substr(fld[i],2))
            # uppercase the first character of any second word
            if (match (fld[i],/ /)) {
                fld[i] = substr(fld[i],1,RSTART) toupper(substr(fld[i],RSTART+1,1)) (substr(fld[i],RSTART+2))
            }
        }
        # Put the finalized header before the description
        if (numFields > 3 ) {
            sub (/Drama-crime/,"Drama - crime",fld[1])
            gsub (/ /,"",fld[4])
            showDescriptor =  fld[1] "\t" fld[2] "\t" fld[(numFields-1)] "\t" fld[(numFields)] "\t"
            headerAdded = "yes"
        }
    } else {
        # if we didn't find a header in this block, add a blank one
        if (headerAdded == "no") {
            printf ("==> Added blank header for \"%s\"\n", showTitle) >> ERRORS
            showDescriptor = "\t\t\t\t"
        }
        # We found a description, clean it up and add it
        gsub (/  */," ")
        gsub (/&#x27;/,"'")
        gsub (/&#39;/,"'")
        gsub (/&quot;/,"\"")
        gsub (/&amp;/,"\\&")
        gsub (/&lsquo;/,"’")
        gsub (/&rsquo;/,"’")
        gsub (/&ldquo;/,"“")
        gsub (/&rdquo;/,"”")
        gsub (/\r/," ")
        # if it's not the last line of the description, add it
        if ($0 !~ /"\>/) {
            printf ("==> Multi line description in \"%s\"\n", showTitle) >> ERRORS
            showDescriptor = showDescriptor $0
        } else {
            # if it's the last line of the description, add it
            sub (/"\>/,"")
            showDescriptor = showDescriptor $0
        }
    }
    # print "==> showDescriptor = " showDescriptor > "/dev/stderr"
    next
}

# Show URL
#    <meta property="og:url" content="https://watch.mhzchoice.com/gasmamman">
/<meta property="og:url" content=/ {
    split ($0,fld,"\"")
    showURL = fld[4]
    # print "==> showURL = " showURL > "/dev/stderr"
    next
}

# Show seasons
#    <h2 class="site-font-secondary-color site-font-primary-family collection-stats">
#        3 Seasons
#    </h2>
# Extract only the number of seasons, # but if this is page 2 skip to avoid double counting
/<h2 class=.*collection-stats"/,/<\/h2>/ {
    sub (/^ */,"")
    # Only if there are two or more seasons, a show with only one season doesn't have this
    if ($0 ~ / Season/) {
        showSeasons = $1
        next
    }
}

### Begin episode processing

# Episode URL(s) and -c-x Episode Number
#     <div class="grid-item-padding">
#    <a href="https://watch.mhzchoice.com/gasmamman/season:1/videos/gasmamman-episode-01-sn-1-ep-1-1" \
#        ...
#        Gåsmamman: Episode 01 (Sn 1 Ep 1)&quot;}">
/<div class="grid-item-padding">/,/<a href="https:/ {
    if ($0 ~ /<a href="https:/) {
        split ($0,fld,"\"")
        episodeURL = fld[2]
        shortEpisodeURL = episodeURL
        sub (/.*watch/,"watch",shortEpisodeURL)
        # print "==> episodeURL = " episodeURL > "/dev/stderr"
        if (match (shortEpisodeURL, /-c-x[[:digit:]]{3,4}$/)) {
            cxEpisodeNumber = substr(shortEpisodeURL, RSTART+RLENGTH-2, 2)
            # print shortEpisodeURL " cx " cxEpisodeNumber > "/dev/stderr"
        }
        next
    }
}

# Episode Duration(s)
# Used to be on one line
#    <div class="duration-container is-locked">44:15</div>
#
# Now it's on six
#    <div class="duration-container
#      is-locked
#      "
#    >
#      47:58
#    </div>
# Extract the duration
/<div class="duration-container/,/<\/div>/ {
    gsub (/ /,"")
    if ($0 ~ /[[:digit:]]+:[[:digit:]]+/)
        episodeDuration = $0
    # Spreadsheets decipher 2 part durations as time-of-day so make sure they're 3 parts
    if (split (episodeDuration, tm, ":") == 2)
        episodeDuration = "00:" episodeDuration
    if ($0 ~ /<\/div>/) {
        # print "==> episodeDuration = " episodeDuration > "/dev/stderr"
        next
    }
}

# Episode Titles, Types, and Numbers
#    <h3 class="tooltip-item-title site-font-primary-family"> \
#        <strong>Gåsmamman: Episode 01 (Sn 1 Ep 1)</strong></h3>
/<h3 class="tooltip-item-title/{
    split ($0,fld,"[<>]")
    episodeTitle = fld[5]
    gsub (/&#x27;/,"'",episodeTitle)
    gsub (/&#39;/,"'",episodeTitle)
    gsub (/&quot;/,"\"\"",episodeTitle)
    gsub (/&amp;/,"\\&",episodeTitle)
    sub (/^[[:space:]]/,"",episodeTitle)
    sub (/[[:space:]]+$/,"",episodeTitle)

    # Make Montalbano titles agree with MHz listing
    if (episodeTitle ~ /^Montalbano|^Detective Montalbano:/) {
        sub (/\(Ep/,"(Sn 1 Ep",episodeTitle)
        sub (/^Montalbano:/,"Detective Montalbano:",episodeTitle)
        sub (/^Montalbano and Me/,"Detective Montalbano: Montalbano and Me",episodeTitle)
        # print "==> Montalbano episodeTitle = " episodeTitle > "/dev/stderr"
    }

    # Fix inconsistencies in "Murder In..."
    if (showTitle ~ /^Murder In/) {
        sub (/^Murder In…: /,"",episodeTitle)
        sub (/^Murder In… /,"",episodeTitle)
        sub (/^Murder In\.\.: /,"",episodeTitle)
        sub (/^Murder In\.\.\.: /,"",episodeTitle)
        sub (/^Murder In\.\.\. /,"",episodeTitle)
        sub (/^Murder In\.\.\./,"",episodeTitle)
    }

    # If start of episodeTitle == showTitle followed by ": " or " - ", remove the redundant part.
    if (match (episodeTitle, showTitle ": ") == 1 || \
        match (episodeTitle, showTitle ":") == 1 || \
        match (episodeTitle, showTitle "; ") == 1 || \
        match (episodeTitle, showTitle " - ") == 1) {
        episodeTitle = substr(episodeTitle, RLENGTH + 1)
    }

    # Episode Types(s)
    # Default episodeType to "E"
    episodeType = "E"
    # If episode is a BONUS:, set episodeType to "X"
    if (episodeTitle ~ /BONUS/ && showTitle !~ /^Detective Montalbano/) {
        episodeType = "X"
    }
    # If episode is a Trailer (i.e. First look), set episodeType to "T"
    if (episodeTitle ~ /^PR \|/) {
        seasonEpisodes = seasonEpisodes - 1
        episodeType = "T"
        prEpisodeNumber += 1
        # print shortEpisodeURL " pr " prEpisodeNumber > "/dev/stderr"
    }
    # print "==> episodeType = " episodeType > "/dev/stderr"

    # Season and episode numbers
    #
    # snEpisodeNumber processing
    # If season only has one episode, set snEpisodeNumber to 1
    if (seasonEpisodes == 1) {
        snEpisodeNumber = 1
    }
    # If episode is upcoming, i.e. - EP 507" Available... use its episode number
        if (match (episodeTitle, /-[[:space:]]{1,2}EP [[:digit:]]{3,4}/)) {
            snEpisodeNumber = substr(episodeTitle, RSTART+RLENGTH-2, 2)
        # print shortEpisodeURL " sn " snEpisodeNumber > "/dev/stderr"
    }
    # Grab the Episode Number from the trailing (Sn 1 Ep 1)
    # Episode Number(s)
    if (match (episodeTitle,/\(.*[Ee][Pp][ ]*[[:digit:]]+[[:space:]]*\)/)) {
        snEpisodeNumber = substr(episodeTitle, RSTART, RLENGTH)
        sub (/.*[[:space:]]/,"",snEpisodeNumber)
        sub (/\).*/,"",snEpisodeNumber)
        # print shortEpisodeURL " sn " snEpisodeNumber > "/dev/stderr"
    }
    # Special case for Special Division (sn-1-ep-1)
    if (shortEpisodeURL ~ /special-division-/) {
        if (match (shortEpisodeURL,/-ep-[[:digit:]]+/)) {
            snEpisodeNumber = substr(shortEpisodeURL, RSTART+4, RLENGTH-4)
            # print shortEpisodeURL " sn " snEpisodeNumber > "/dev/stderr"
        }
    }
    # Special case for voiceless-episode-04
    if (shortEpisodeURL ~ /voiceless-episode-04/) {
        snEpisodeNumber = 4
    }
    #
    # cxEpisodeNumber processing
    # Octopus and some others uses -c-0
    if (match (shortEpisodeURL, /-c-[[:digit:]]{5}/)) {
        if (snEpisodeNumber == "" && prEpisodeNumber == "") {
            cxEpisodeNumber = substr(shortEpisodeURL, RSTART+RLENGTH-3, 3)
            # print shortEpisodeURL " cx " cxEpisodeNumber > "/dev/stderr"
         }
    }
    # Special case for Maigret
    if (shortEpisodeURL ~ /maigrt-c-x0110/) {
        cxEpisodeNumber = 1
    }
    # 
    # Episode title season/episode verification and standardization
    # print "==> episodeTitle = " episodeTitle > "/dev/stderr"
    # Handle normal (Sn 1 Ep 1) with variations in spacing and capitalization
    # and ones missing the second letter (Sn 1 E 1), (S1 E1), or wrong second letter (Sm 1 Ep 1)
    if (match (episodeTitle,\
        /[Ss][Nnm]*[ ]*[[:digit:]]+[ ]+[Ee][Pp]*[ ]*[[:digit:]]+[[:space:]]*\)/))  {
            if (episodeTitle !~ / \(Sn [[:digit:]]+ Ep [[:digit:]]+\)/)
                printf ("==> Malformed Sn/Ep in \"%s: %s\"\n", showTitle, episodeTitle) >> ERRORS
            sub (/[ ]*\([ ]*[Ss][Nnm]*[ ]*[[:digit:]]+[ ]+[Ee][Pp]*[ ]*[[:digit:]]+[[:space:]]*\)/,\
                "",episodeTitle)
            # print shortEpisodeURL " sn " snEpisodeNumber > "/dev/stderr"
            # print shortEpisodeURL " = " episodeNumber > "/dev/stderr"
            # print "==> episodeTitle = " episodeTitle > "/dev/stderr"
    }
    next
}

### Find media-episode number if one exists
# <h4 class="transparent"><span class='media-identifier media-episode'>Episode 1</span> </h4>
# But keep other processing if it is missing
# <h4 class="transparent"><span class='media-identifier media-episode'></span> </h4>
/<h4 class="transparent"><span class='media-identifier media-episode'>Episode/ {
    split ($0,fld,"[<>]")
    mdEpisodeNumber = fld[5]
    sub (/Episode /,"",mdEpisodeNumber)
    # print $0 > "/dev/stderr"
    # print "==> " showTitle " mdEpisodeNumber " mdEpisodeNumber > "/dev/stderr"
}

### Wrap-up episode processing when Episode Description is found
### print only on LONG_SPREADSHEET
/<h4 class="transparent"><span class='media-identifier/,/<\/div>/ {
    sub (/^ */,"")
    # print $0 > "/dev/stderr"

    # Episode Description(s)
    #    <div class="transparent padding-top-medium">
    #      <p>Preparing for her sister's wedding, Sonja's idyllic life is shattered by tragedy.
    #    </p>
    if ($0 ~ /<p>/) {
        split ($0,fld,"[<>]")
        paragraph = fld[3]
        gsub (/&amp;/,"\\&",paragraph)
        # Could be in multiple paragraphs
        descriptionLinesFound += 1
        if (paragraph != "")
            episodeDescription = episodeDescription (descriptionLinesFound == 1 ? "" : " ") paragraph
        gsub (/&amp;/,"\\&",episodeDescription)
        gsub (/&#x27;/,"'",episodeDescription)
        gsub (/&#39;/,"'",episodeDescription)
        # print "descriptionLinesFound = " descriptionLinesFound > "/dev/stderr"
        # print "==> episodeDescription from <p> = \n" episodeDescription > "/dev/stderr"
        next
    }
    #  =HYPERLINK("https://watch.mhzchoice.com/gasmamman/season:1/videos/gasmamman-episode-01-sn-1-ep-1-1";\
    #  "Gasmamman, S01E01, Gåsmamman: Episode 01 (Sn 1 Ep 1)")
    if ($0 ~ /<\/div>/) {
        # Make sure episodeDescription is valid
        if (episodeDescription == "") {
            if (episodeType == "T") {
                episodeDescription = episodeTitle
                # print "==> episodeDescription from title = " episodeDescription > "/dev/stderr"
            } else {
                print "==> No description: " shortEpisodeURL >> ERRORS
            }
        }
        if (episodeDescription ~ /^PR \|/)
            sub (/^PR \| /,"",episodeDescription)
        # print "==> episodeDescription = \n" episodeDescription > "/dev/stderr"
        #
        # Check for valid seasonNumber and episodeNumber before using them
        if (seasonNumber == "")
            printf ("==> Missing seasonNumber in \"%s: %s\" %s\n", showTitle,
                    episodeTitle, shortEpisodeURL) >> ERRORS
        #
        # Pick episode number using hierarchy of priorities
        # Special case for Montalbano
        if (cxEpisodeNumber != "" && showTitle !~ /^Detective Montalbano/ )
            episodeNumber = cxEpisodeNumber
        if (prEpisodeNumber != "" && episodeNumber == "")
            episodeNumber = prEpisodeNumber
        if (mdEpisodeNumber != "" && episodeNumber == "")
            episodeNumber = mdEpisodeNumber
        if (snEpisodeNumber != "" && episodeNumber == "")
            episodeNumber = snEpisodeNumber
        #
        if (episodeNumber == "") {
            printf ("==> Missing episodeNumber %s in \"%s: %s\" %s\n", mdEpisodeNumber,
                    showTitle, episodeTitle, shortEpisodeURL) >> ERRORS
            episodeNumber = 0
        }
        #
        # if (mdEpisodeNumber != "" && mdEpisodeNumber != episodeNumber) {
        #     print shortEpisodeURL " = " episodeNumber >> "NUMBERS.csv"
        #     print "mdEpisodeNumber = " mdEpisodeNumber >> "NUMBERS.csv"
        # }
        episodeLink = sprintf ("=HYPERLINK(\"%s\";\"%s, S%02d%s%02d, %s\")", episodeURL, showTitle,
                    seasonNumber, episodeType, episodeNumber, episodeTitle)
        #
        # Make sure episodeDuration is valid
        if (split (episodeDuration, tm, ":") == 3) {
            # Canonicalize episodeDuration to 3 parts like other services
            episodeDuration = sprintf ("%02d:%02d:%02d",tm[1],tm[2],tm[3])
        } else {
            printf ("==> Bad episodeDuration %s in \"%s: %s\"\n", episodeDuration, showTitle,
                    episodeTitle) >> ERRORS
            episodeDuration = ""
        }
        #
        # Print "episode" line
        # printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", showTitle, shortEpisodeURL,
        #    mdEpisodeNumber, prEpisodeNumber, cxEpisodeNumber, snEpisodeNumber,
        #    episodeNumber)  >> "MHz-columns/episodeNumbers.csv"
        printf ("%s\t\t\t%s\t\t\t\t\t%s\n", episodeLink, episodeDuration, episodeDescription)
        #
        # Look for directors
        director_name = episodeDescription
        # Skip UTF-8 for now...
        # if (gsub (/\xc2\xa0/," ",director_name)) {
            # printf ("==> UTF-8 non-breaking-space in %s, S%02d%s%02d, %s\n", showTitle, seasonNumber,
                    # episodeType, episodeNumber, episodeTitle) >> ERRORS
            # print "    " episodeDescription >> ERRORS
        # }
        if (director_name ~ /[Dd]irected by /) {
            sub (/.*[Dd]irected by /,"",director_name)
            sub (/,.*$/,"",director_name)
            sub (/ [0-9][0-9][0-9][0-9]\./,"",director_name)
            sub (/[[:space:]]+$/,"",director_name)
            sub (/\.$/,"",director_name)
            # Special case director names
            if (director_name ~ /Manetti Bros/)
                director_name = "The Manetti Bros."
            if (director_name ~ /Andrea and Antonio Frazzi/)
                director_name = "Andrea Frazzi and Antonio Frazzi"
            #
            if (match (director_name, " and ") || match (director_name, " & ")) {
                dname = substr(director_name,1,RSTART-1)
                director_name = substr(director_name,RSTART+RLENGTH)
                printf ("%s\tdirector\ttv_show\t%s\n", dname, showTitle) >> RAW_CREDITS
            }
            printf ("%s\tdirector\ttv_show\t%s\n", director_name, showTitle) >> RAW_CREDITS
        }
        # Make sure there is no carryover
        descriptionLinesFound = 0
        episodeLink = ""
        episodeURL =""
        shortEpisodeURL = ""
        episodeType = ""
        episodeNumber = ""
        cxEpisodeNumber = ""
        mdEpisodeNumber = ""
        prEpisodeNumber = ""
        snEpisodeNumber = ""
        episodeTitle = ""
        episodeDuration = ""
        episodeDescription =""
    }
}

### Wrap-up show processing - print on standard out

# Footer at end of file
#    <footer class="footer--site border-top site-border-color site-background-color \
#        padding-top-medium padding-bottom-medium ">
/<footer class=/ {
    # print "Wrap up season " seasonURL  > "/dev/stderr"
    #  =HYPERLINK("https://watch.mhzchoice.com/gasmamman";"Gasmamman")
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    #
    # Shows with only one season have a blank showSeasons
    if (showSeasons == "")
        showSeasons = 1
    # in most cases, showSeasons = the final season number, i.e.
    # a show with two seasons would have seasons 1 and 2
    finalSeason = showSeasons
    # Special case discontinuous seasons, e.g. 2 seasons, but numbered 1 and 3
    if (showURL ~ /\/mammon$/)
        finalSeason = 2
    if (showURL ~ /\/wallander$/)
        finalSeason = 3
    #
    # Wrap show, i.e. but only on final season in order to prevent multiples
    # print "==> " showURL " - seasonNumber = " seasonNumber  > "/dev/stderr"
    # print "==> " showTitle " - finalSeason = " finalSeason  > "/dev/stderr"
    if (seasonNumber > finalSeason ) {
        # This should be OK, as printing any single valid season will work - however ...
        printf ("==> Season number %d beyond final season %d: %s\n", seasonNumber, finalSeason,
                shortSeasonURL) >> ERRORS
    }
    if (seasonNumber == finalSeason ) {
        # Print "show" line
        printf ("%s\t%s\t\t\t%s\n", showLink, showSeasons, showDescriptor)
    }
    #
    #  =HYPERLINK("https://watch.mhzchoice.com/gasmamman/season:1";"Gasmamman, S01, Season 1")
    if (page2 != "yes") {
        seasonLink = sprintf ("=HYPERLINK(\"%s\";\"%s, S%02d, %s\")", seasonURL, showTitle,
                   seasonNumber, seasonTitle)
        # print "==> seasonURL = " seasonURL  > "/dev/stderr"
        # print "==> seasonLink = " seasonLink  > "/dev/stderr"
        # Don't print redundant showDescriptor for season 1
        if (seasonNumber == 1)
            showDescriptor = ""
        # Print "season" line
        printf ("%s\t\t%s\t\t%s\n", seasonLink, seasonEpisodes, showDescriptor)
    }
    #
    # Make sure there is no carryover
    showLink = ""
    showURL = ""
    showTitle = ""
    showSeasons = ""
    showDescriptor = ""
    # print "" > "/dev/stderr"
    #
    page2 = ""
    seasonLink = ""
    seasonURL = ""
    shortSeasonURL = ""
    seasonNumber = ""
    seasonTitle = ""
    seasonEpisodes = ""
}
