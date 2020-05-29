# Print the processed "Episode" lines from a WebScraper csv file saved in tsv format

# INVOCATION:
#       awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
#           -f getBBoxEpisodesFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE

# Field numbers
#    1 web-scraper-start-url  2 SsnURL     3 SsnURL-href    4 URL        5 Program_Title
#    6 Episode_Title          7 Year       8 Duration       9 Rating    10 Description


BEGIN {
    FS="\t"
    OFS="\t"
    print "Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear(s)\tRating\tDescription"
    print "Type\t#\tSortkey\tURL\tshowTitle\tepisodeTitle\tYear(s)" > "debug.csv"
}

{
    for ( i = 1; i <= NF; i++ ) {
        if ($i == "null")
            $i = ""
    }
}

/\/us\/movie\/|\/us\/episode\// {
    baseURL = $1
    URL = $4
    showTitle = $5
    episodeTitle = $6
    Years = $7
    Duration = $8
    Rating = $9
    Description = $10
    showtype = "S"

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_S[[:digit:]]*_E[[:digit:]]*_[[:digit:]]*$/) {
        # /us/episode/35_Days_S3_E8_23851
        # Season 3, Episode 8
        seasonNumber = substr(fld[nflds-2], 2)
        episodeNumber = substr(fld[nflds-1], 2)
        sortkey = sprintf ("%s%02dE%03d", showtype, seasonNumber, episodeNumber)
        c1Num += 1
        printf ("c1\t%d\t%s\t%s\t%s\t%s\t%s\n",c1Num,sortkey,URL,showTitle,episodeTitle,Years) >>"debug.csv"
    } else if (URL ~ /_E[[:digit:]]*_[[:digit:]]*$/) {
        # /us/episode/35_Hours_E1_26129
        # 35 Hours, Episode 1
        seasonNumber = "99"
        episodeNumber = substr(fld[nflds-1], 2)
        sortkey = sprintf ("%s%02dE%03d", showtype, seasonNumber, episodeNumber)
        c2Num += 2
        printf ("c2\t%d\t%s\t%s\t%s\t%s\t%s\n",c2Num,sortkey,URL,showTitle,episodeTitle,Years) >>"debug.csv"
    } else if (URL ~ /Episode_[[:digit:]]*_[[:digit:]]*$/) {
        # /us/episode/Episode_5_26089
        # Season 4, Episode 5
        seasonNumber = "98"
        episodeNumber = substr(fld[nflds-1], 1)
        sortkey = sprintf ("%s%02dE%03d", showtype, seasonNumber, episodeNumber)
        c3Num += 3
        printf ("c3\t%d\t%s\t%s\t%s\t%s\t%s\n",c3Num,sortkey,URL,showTitle,episodeTitle,Years) >>"debug.csv"
    } else {
        URL ~ /^\/us\/movie\// ? showtype = "M" : showtype = "E"
        # /us/episode/Orkneys_Stone_Age_Temple_7144
        # A History of Ancient Britain Special, Orkney's Stone Age Temple
        sortkey = sprintf ("%s%05d", showtype, fld[nflds])
        c4Num += 4
        printf ("c4\t%d\t%s\t%s\t%s\t%s\t%s\n",c4Num,sortkey,URL,showTitle,episodeTitle,Years) >>"debug.csv"
    }

    # Convert duration from minutes to HMS
    sub( / min/,"",Duration)
    secs = 0
    mins = Duration % 60
    hrs = int(Duration / 60)
    HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (HMS == "00:00:00")
        HMS = ""

    # Special processing for some shows is needed in all getBBox*From-webscraper.awk scripts.
    # "Changed" message and counting revisedTitles are only in getBBoxProgramsFrom-webscraper.awk
    # so they are not repeated for each episode and each season.
    if (baseURL ~ /Maigret_15974$/) {
        showTitle = "Maigret (2016)"
    }
    if (baseURL ~ /Maigret_\(1992\)_15928$/) {
        showTitle = "Maigret (1992)"
    }
    if (baseURL ~ /Porridge_9509$/) {
        showTitle = "Porridge (1974-1977)"
    }
    if (baseURL ~ /Porridge_14747$/) {
        showTitle = "Porridge (2016-2017)"
    }

    # Get rid of redundant "Series #" or "Series #" from episodeTitle
    if (match (episodeTitle, /^Season [[:digit:]]*, |^Series [[:digit:]]*, /))
        episodeTitle = substr(episodeTitle,RLENGTH+1)

    # Get rid of initial/trailing quotes in showTitle
    # "BBC Three's ""Murdered By..."" Collection Trailer"
    if (showTitle ~ /^".*"$/) {
        revisedTitles += 1
        printf ("==> Fixed quoted title: www.britbox.com%s\n", URL) >> ERROR_FILE
        # printf ("    %s\n", showTitle) >> ERROR_FILE
        sub (/^"/,"",showTitle)
        sub (/"$/,"",showTitle)
        # printf ("    %s\n", showTitle) >> ERROR_FILE
    }

    # Non-existent fields in movies or episodes
    if (URL ~ /^\/us\/movie\//) {
        depth = "1"
        numSeasons = 1
        numEpisodes = 1
        fullTitle = showTitle
    } else {
        depth = "2"
        numSeasons = ""
        numEpisodes = ""
        fullTitle = showTitle ", " sortkey ", " episodeTitle
    }

    # Fix two consecutive double quotes in showTitle, but leave in fullTitle 
    gsub ("\"\"","\"",showTitle)

    # Fix HEX quotes in Description
    gsub ("\xc2\x91","\"",Description)
    gsub ("\xc2\x92","\"",Description)

    # Create spreadsheet row in common format
    savedLine = sprintf \
        ("%s (%s) %s %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s\"\)\t%s\t%s\t%s\t%s\t%s\t%s",\
         showTitle, depth, Years, sortkey, URL, fullTitle, numSeasons, numEpisodes, \
         HMS, Years, Rating, Description)

    # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
    sub (/^'/,"",savedLine)

    print savedLine
    next
}

/\/us\/show\// {
    # Shouldn't get here
    badEpisodes += 1
    URL = $4
    nflds = split (URL,URLflds,"/")
    printf ("==> Upstream error in %s\n", FILENAME)  >> ERROR_FILE 
    print "==> Found /us/show/ in episodes: " URLflds[nflds]  >> ERROR_FILE
}

END {
    printf ("In getBBoxEpisodesFrom-webscraper.awk\n") > "/dev/stderr"
    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? field = "title" : field = "titles"
        printf ("    %2d %s revised in %s\n", revisedTitles, field, FILENAME) > "/dev/stderr"
    }
    if (badEpisodes > 0 ) {
        badEpisodes == 1 ? field = "URL" : field = "URLs"
        printf ("    %2d extra /show/ %s in %s\n", badEpisodes, field, FILENAME) > "/dev/stderr"
    }
}
