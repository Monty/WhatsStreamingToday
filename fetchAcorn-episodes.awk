# Given the output of an episode file (for example) curl -s https://acorn.tv/800words
# create lists of titles, descriptions, episodes and seasons
# to be pasted into a spreadsheet. Note that IN_CANADA affects processing.
#
# Invoked with file parameters as follows:
# awk -v TITLE_FILE=$TITLE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
#     -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE \
#     -v IN_CANADA=$IN_CANADA -f fetchAcorn-episodes.awk

/span itemprop="name"/ {
    sub (/.*name">/,"")
    sub (/<.*/,"")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    episodeLinesFound = 0
    episodeStr = ""
    print >> TITLE_FILE
}

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
}

/itemprop="numberOfSeasons"/ {
    sub (/.*content="/,"")
    sub (/" \/>.*/,"")
    print >> SEASONS_FILE
}

/itemprop="numberOfEpisodes"/ {
    sub (/.*content="/,"")
    sub (/" \/>.*/,"")
    episodeLinesFound += 1
    if (episodeLinesFound != 1) 
        episodeStr = episodeStr "+" $0
}

END { print (episodeLinesFound == 1 ? "=0" : "=" episodeStr) >> EPISODES_FILE }
