# Produce an episode spreadsheet from TV Episodes html

# INVOCATION:
# awk -v ERRORS=$ERRORS -f getBBoxEpisodesFromHTML.awk "$TV_EPISODE_HTML" |
#     sort -fu --key=4 --field-separator=\" >"$EPISODES_CSV"

BEGIN {
    # Print spreadsheet header
    printf ("Title\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t")
    printf ("Content_Type\tContent_ID\tItem_Type\tDate_Type\tOriginal_Date\t")
    printf ("Sn_#\tEp_#\t1st_#\tLast_#\n")
}

# "/tv/genres/Mystery"
/"\/tv\/genres\// {
    split ($0,fld,"\/")
    genre = fld[4]
    sub (/".*/,"",genre)
    # print "genre = " genre > "/dev/stderr"
}

# "type": "episode",
/"type": "episode",/ {
    contentType = "tv_episode"
    itemType = "episode"
    # Make sure no fields have been carried over due to missing keys
    episodeName = ""
    fullTitle = ""
    numSeasons = ""
    numEpisodes = ""
    duration = ""
    yearRange = ""
    year = ""
    rating = ""
    description = ""
    contentId = ""
    showId = ""
    showTitle = ""
    seasonId = ""
    dateType = ""
    originalDate = ""
    episodePath = ""
    seasonNumber = ""
    episodeNumber = ""
    SnEp = ""
    firstLineNum = ""
    lastLineNum = ""
    full_URL = ""
    #
    firstLineNum = NR
}

# "shortDescription": "A young Rhys is shot dead in the house. Rewind 15 days and we meet four siblings and their families as they arrive at an isolated farmhouse to scatter their mother&#39;s ashes.",
#
# Note: Some descripotions may contain quotes
/"shortDescription": "/ {
    sub (/.*"shortDescription": "/,"")
    sub (/",$/,"")
    description = $0
    gsub (/&amp;/,"\\&",description)
    gsub (/&#160;/," ",description)
    gsub (/&#39;/,"'",description)
    gsub (/&#233;/,"é",description)
    gsub (/&#239;/,"ï",description)
    # print "description = " description > "/dev/stderr"
}

# "code": "TVPG-TV-PG",
/"code": "TVPG-/ {
    split ($0,fld,"\"")
    rating = fld[4]
    sub (/TVPG-/,"",rating)
    # print "rating = " rating > "/dev/stderr"
}

# "path": "/episode/15_Days_S1_E1_p07l24yd",
/"path": "\/episode\// {
    # Goal: 15_Days_S01E001_Episode_1_p07l24yd > S01E001
    split ($0,fld,"\"")
    episodePath = fld[4]
    full_URL = "https://www.britbox.com/us" episodePath
    # print "full_URL = " full_URL > "/dev/stderr"
    numFields = split (episodePath,fld,"_")
    seasonNumber = fld[numFields - 2]
    sub (/S/,"",seasonNumber)
    # print "seasonNumber = " seasonNumber > "/dev/stderr"
    episodeNumber = fld[numFields - 1]
    sub (/E/,"",episodeNumber)
    # print "episodeNumber = " episodeNumber > "/dev/stderr"
    SnEp = sprintf ("S%02dE%03d", seasonNumber, episodeNumber)
}

# "releaseYear": 2019,
/"releaseYear": / {
    dateType = "releaseYear"
    split ($0,fld,"\"")
    year = fld[3]
    sub (/: /,"",year)
    sub (/,.*/,"",year)
    # print "year = " year > "/dev/stderr"
}

# "episodeName": "Episode 1",
/"episodeName": "/ {
    split ($0,fld,"\"")
    episodeName = fld[4]
    gsub (/&amp;/,"\\&",episodeName)
    gsub (/&#39;/,"'",episodeName)
    # print "episodeName = " episodeName > "/dev/stderr"
}

# "showId": "24474",
/"showId": / {
    split ($0,fld,"\"")
    showId = fld[4]
    # print "showId = " showId > "/dev/stderr"
}

# "showTitle": "15 Days",
/"showTitle": / {
    split ($0,fld,"\"")
    showTitle = fld[4]
    gsub (/&amp;/,"\\&",showTitle)
    gsub (/&#39;/,"'",showTitle)
    # print "showTitle = " showTitle > "/dev/stderr"
}

# "seasonId": "24475",
/"seasonId": / {
    split ($0,fld,"\"")
    seasonId = fld[4]
    # print "seasonId = " seasonId > "/dev/stderr"
}

# "duration": 2690,
/"duration": / {
    split ($0,fld,"\"")
    seconds = fld[3]
    sub (/: /,"",seconds)
    sub (/,.*/,"",seconds)
    duration = "0:" int(seconds / 60 )
    # print "duration = " duration > "/dev/stderr"
}

# "customId": "p07kvw8d",
/"customId": "/ {
    totalEpisodes += 1
    lastLineNum = NR
    split ($0,fld,"\"")
    contentId = fld[4]
    # print "contentId = " contentId > "/dev/stderr"

    # This should be the last line of every episode.
    # So finish processing and add line to spreadsheet

    # Turn episodeName into a HYPERLINK
    # Goal: 15_Days_S01E001_Episode_1_p07l24yd > 15 Days, S01E001, Episode 1
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" showTitle ", " \
              SnEp ", "episodeName "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # Print a spreadsheet line
    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
            fullTitle, numSeasons, numEpisodes, duration,
            genre, year, rating, description)
    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
            contentType, contentId, itemType, dateType,
            originalDate, seasonNumber, episodeNumber)
    printf ("%d\t%d\n", firstLineNum, lastLineNum)
}

END {
    printf ("In getBBoxEpisodesFromHTML.awk \n") > "/dev/stderr"

    totalEpisodes == 1 ? pluralEpisodes = "episode" : pluralEpisodes = "episodes"
    printf ("    Processed %d %s\n", totalEpisodes, pluralEpisodes) > "/dev/stderr"

    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf ("%8d %s revised in %s\n",
                revisedTitles, plural, FILENAME) > "/dev/stderr"
    }
}
