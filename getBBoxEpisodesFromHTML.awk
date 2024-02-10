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
/^    "\/tv\/genres\// {
    split ($0,fld,"\/")
    genre = fld[4]
    sub (/".*/,"",genre)
    # print "genre = " genre > "/dev/stderr"
}

# <title>15 Days S1 - Mystery | BritBox</title>
/^        "type": "episode",/ {
    # Make sure no fields have been carried over due to missing keys
    title = ""
    fullTitle = ""
    numSeasons = ""
    numEpisodes = ""
    duration = ""
    yearRange = ""
    year = ""
    rating = ""
    description = ""
    contentType = ""
    contentId = ""
    seasonId = ""
    itemType = ""
    dateType = ""
    originalDate = ""
    seasonNumber = ""
    episodeNumber = ""
    firstLineNum = ""
    lastLineNum = ""
    full_URL = ""
    #
    firstLineNum = NR
}

# "title": "15 Days S1 E1",
/^        "title": "/ {
    totalEpisodes += 1
    split ($0,fld,"\"")
    title1 = fld[4]
    gsub (/&amp;/,"\\&",title1)
    gsub (/&#39;/,"'",title1)
    # print "title1 = " title1 > "/dev/stderr"
}

# "shortDescription": "A young Rhys is shot dead in the house. Rewind 15 days and we meet four siblings and their families as they arrive at an isolated farmhouse to scatter their mother&#39;s ashes.",
#
# Note: Some descripotions may contain quotes
/^        "shortDescription": "/ {
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
/^          "code": "TVPG-/ {
    split ($0,fld,"\"")
    rating = fld[4]
    sub (/TVPG-/,"",rating)
    # print "rating = " rating > "/dev/stderr"
}

# "path": "/episode/15_Days_S1_E1_p07l24yd",
/^        "path": "\/episode\// {
    split ($0,fld,"\"")
    full_URL = "https://www.britbox.com/us" fld[4]
    # print "full_URL = " full_URL > "/dev/stderr"
}

# "releaseYear": 2019,
/^        "releaseYear":/ {
    split ($0,fld,"\"")
    year = fld[3]
    sub (/: /,"",year)
    sub (/,.*/,"",year)
    # print "year = " year > "/dev/stderr"
}

# "episodeName": "Episode 1",
/^        "episodeName": "/ {
    split ($0,fld,"\"")
    title = fld[4]
    gsub (/&amp;/,"\\&",title)
    gsub (/&#39;/,"'",title)
    # print "title = " title > "/dev/stderr"
}

# "customId": "p07kvw8d",
/"customId": "/ {
    lastLineNum = NR
    split ($0,fld,"\"")
    contentId = fld[4]
    # print "contentId = " contentId > "/dev/stderr"

    # This should be the last line of every episode.
    # So finish processing and add line to spreadsheet

    # Turn title into a HYPERLINK
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" title "\")"
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
