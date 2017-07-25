# Create column files with lists of series titles, descriptions, number 
# of seasons, and number of episodes, to be pasted into a spreadsheet.
# Note that IN_CANADA affects processing.
#
# Create a separate file with a line for each episode containing
# seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
# episodeTitle, & episodeDuration with the same columns as the primary
# spreadsheet so they can be combined into one.
#
# INVOCATION:
#       curl -s https://acorn.tv/192/ \
#           | awk -v TITLE_FILE=$TITLE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
#           -v NUM_SEASONS_FILE=$NUM_SEASONS_FILE -v NUM_EPISODES_FILE=$NUM_EPISODES_FILE \
#           -v EPISODE_URL_FILE=$EPISODE_URL_FILE -v IN_CANADA=$IN_CANADA \
#           -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$lastRow \
#           -f getAcornFrom-seriesPages.awk
#
# INPUT:
#        <title>Acorn TV | 19-2</title>
#  ---
#        <span itemprop="name">19-2</span>
#        <meta itemprop="numberOfEpisodes" content="30" />
#        <meta itemprop="numberOfSeasons" content="3" />
#  ---
#        <p id="franchise-description" itemprop="description">"The writing is sublime" (New \
#        York Times) in this anything-but-a-procedural cop drama ... as reluctant partners \
#        patrolling the streets of Montreal. Not Available in Canada. CC Available.</p>
#  ---
#        <meta itemprop="seasonNumber" content="1" />
#  ---
#        <a itemprop="url" href="https://acorn.tv/192/series1/partners">
#  ---
#        <meta itemprop="timeRequired" content="T44M06S" />
#  ---
#        <h5 itemprop="name">Partners</h5>
#  ---
#        <h6>Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Season 9 Christmas Special: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Series 1: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Series 1 (Set 1): Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Series 10 (Sets 13 - 14): Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Series 19 (Part One): Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Set 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Mini Series: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Miniseries: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>Black Widows Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#        <h6>A Dance to the Music of Time: Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Christmas Special : Episode <span itemprop="episodeNumber">1</span></h6>
#        <h6>Feature Film: Episode <span itemprop="episodeNumber">1</span></h6>
#
#  OUTPUT:
#       $EPISODE_INFO_FILE
#

# Extract and save whether this is a miniseries
/<h6>Miniseries:/ || /<h6>Mini Series:/ {
    showType = "M"
}

# Extract the series title
/<title>/ {
    sub (/.*<title>Acorn TV \| /,"")
    sub (/<.*/,"")
    gsub (/&amp;/,"\\&")
    # gsub (/&#x27;/,"'")
    # gsub (/&quot;/,"\"\"")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    episodeLinesFound = 0
    numEpisodesStr = ""
    seriesTitle = $0
    print seriesTitle >> TITLE_FILE
    next
}

# Extract the number of episodes in the series
/itemprop="numberOfEpisodes"/ {
    split ($0,fld,"\"")
    episodeLinesFound += 1
    if (episodeLinesFound != 1)
        numEpisodesStr = numEpisodesStr "+" fld[4]
    next
}

# Extract the number of seasons in the series
/itemprop="numberOfSeasons"/ {
    split ($0,fld,"\"")
    numSeasons = fld[4]
    print numSeasons >> NUM_SEASONS_FILE
    next
}

# Extract the series description
/id="franchise-description"/ {
    # get rid of boilerplate
    sub (/.*itemprop="description">/,"")
    sub (/<\/p>$/,"")
    # get rid of unnecessary characters and text
    gsub (/\\/,"")
    if (IN_CANADA != "yes") {
        sub (/Series 1 not available in Canada\./,"")
        sub (/Not [Aa]vailable in Canada\./,"")
        sub (/NOT AVAILABLE IN CANADA\./,"")
    }
    sub (/CC Available\. CC Available/,"CC Available")
    # fix sloppy input spacing
    sub (/\.CC Available/,". CC Available")
    gsub (/ \./,".")
    gsub (/  */," ")
    sub (/^ */,"")
    sub (/ *$/,"")
    # fix funky HTML characters
    gsub (/&#39;/,"'")
    print >> DESCRIPTION_FILE
    next
}

# Extract the seasonNumber
/<meta itemprop="seasonNumber" content="/ {
    split ($0,fld,"\"")
    seasonNumber = fld[4]
}

# Extract the episode URL
/<a itemprop="url"/ {
    split ($0,fld,"\"")
    episodeURL = fld[4]
    print episodeURL >> EPISODE_URL_FILE
}

# Extract the episode duration
/<meta itemprop="timeRequired"/ {
    split ($0,fld,"\"")
    split (fld[4],tm,/[TMS]/)
    secs = tm[3]
    mins = tm[2] + int(secs / 60)
    hrs =  int(mins / 60)
    secs %= 60; mins %= 60
    episodeDuration = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    next
}

# Extract the episode title
/<h5 itemprop="name">/ {
    sub (/.*<h5 itemprop="name">/,"")
    sub (/<.*/,"")
    gsub (/&amp;/,"\\&")
    episodeTitle = $0
    next
}

# There are a number of variants in the "episodeNumber" string
#
#       <h6>Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Season 9 Christmas Special: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Series 1: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Series 1 (Set 1): Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Series 10 (Sets 13 - 14): Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Series 19 (Part One): Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Set 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Mini Series: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Miniseries: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>Black Widows Season 1: Episode <span itemprop="episodeNumber">1</span></h6>
#
#       <h6>A Dance to the Music of Time: Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Christmas Special : Episode <span itemprop="episodeNumber">1</span></h6>
#       <h6>Feature Film: Episode <span itemprop="episodeNumber">1</span></h6>

# Extract episode number
/<h6>.*span itemprop="episodeNumber">/ {
    # If we don't know what kind of show it is, use "S"
    if (showType == "")
        showType = "S"
    sub (/.*episodeNumber">/,"")
    sub (/<\/span>.*/,"")
    episodeNumber = $0
    # print seriesTitle " " showType seasonNumber "E" episodeNumber >> "debug.txt"
    printf ("%d\t=HYPERLINK(\"%s\";\"%s, %s%02dE%02d, %s\"\)\t\t\t%s\n", \
        SERIES_NUMBER, episodeURL, seriesTitle, showType, seasonNumber, episodeNumber, episodeTitle, \
        episodeDuration) >>EPISODE_INFO_FILE
}

END { print (episodeLinesFound == 1 ? "=0" : "=" numEpisodesStr) >> NUM_EPISODES_FILE }
