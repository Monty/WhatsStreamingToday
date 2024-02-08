# Produce a shows spreadsheet from TV Shows html

# INVOCATION:
# awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES \
#   -f getBBoxShowsFromHTML.awk "$TV_SHOW_HTML" |
#   sort -fu --key=4 --field-separator=\" >"$SHOWS_CSV"

BEGIN {
    # Print spreadsheet header
    printf ("Title\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t")
    printf ("Content_Type\tContent_ID\tShow_Type\tDate_Type\tOriginal_Date\t")
    printf ("Sn_#\tEp_#\t1st_#\tLast_#\n")
}

# <title>15 Days S1 - Mystery | BritBox</title>
/<title>/ {
    # Make sure no fields have been carried over due to missing keys
    title = ""
    fullTitle = ""
    numSeasons = ""
    numEpisodes = ""
    duration = ""
    genre = ""
    yearRange = ""
    year = ""
    rating = ""
    description = ""
    contentType = ""
    contentId = ""
    showType = ""
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

# <meta name="description" content="Comedy dream team Dawn French and Jennifer Saunders reunite for the first time in ten years for a thirtieth-anniversary show bursting mirth, mayhem, And wigs. Lots and lots of wigs." />
#
# Some descripotions may contain quotes
#
# <meta name="description" content="Reversing the traditional investigative narrative, the crime thriller immediately flashes back to 15 days ago when a young    man is gunned down. Secrets and lies fester within the family, every one’s got a      motive, but who is going to do it?" /
/<meta name="description" / {
    sub (/.*name="description" content="/,"")
    sub (/" \/>.*/,"")
    description = $0
    gsub (/&amp;/,"\\&",description)
    gsub (/&#160;/," ",description)
    gsub (/&#39;/,"'",description)
    gsub (/&#233;/,"é",description)
    gsub (/&#239;/,"ï",description)
    # print "description = " description > "/dev/stderr"
}

# <link rel="canonical" href="https://www.britbox.com/us/show/ 15_Days_p07kvw8d"
/<link rel="canonical" / {
    split ($0,fld,"\"")
    full_URL = fld[4]
    # print "full_URL = " full_URL > "/dev/stderr"
}

# <h1 class="Title-only-mobile">15 Days</h1>
/class="Title-only-mobile"/ {
    split ($0,fld,"[<>]")
    title = fld[3]
    gsub (/&amp;/,"\\&",title)
    gsub (/&#39;/,"'",title)
    # print "title = " title > "/dev/stderr"
}

# "type": "season",
/"type": "season"/ {
    contentType = "tv_show"
    showType = "series"
    totalShows += 1
    # print "showType = " showType > "/dev/stderr"
}

# "/tv/genres/Mystery"
/"\/tv\/genres\// {
    split ($0,fld,"\/")
    genre = fld[4]
    sub (/".*/,"",genre)
    # print "genre = " genre > "/dev/stderr"
}

# "availableSeasonCount": 1,
/"availableSeasonCount":/ {
    split ($0,fld,"\"")
    sub (/.*"availableSeasonCount": /,"")
    sub (/,.*/,"")
    numSeasons = $0
    # print "numSeasons = " numSeasons > "/dev/stderr"
}

# "customId": "p07kvw8d",
/"customId": "/ {
    split ($0,fld,"\"")
    contentId = fld[4]
    # print "contentId = " contentId > "/dev/stderr"
}

# "YearRange": 2019,
# "YearRange": "1992 - 2010",
/"YearRange": "/ {
    dateType = "yearRange"
    split ($0,fld,"\"")
    yearRange = fld[4]
    year = yearRange
    # print "yearRange = \"" yearRange "\""> "/dev/stderr"
}

# "code": "TVPG-TV-PG",
/"code": "TVPG-/ {
    split ($0,fld,"\"")
    rating = fld[4]
    sub (/TVPG-/,"",rating)
    # print "rating = " rating > "/dev/stderr"
}

# "releaseYear": 2019,
/"releaseYear": / {
    if (yearRange == "") {
        dateType = "releaseYear"
        split ($0,fld,"\"")
        year = fld[3]
        sub (/: /,"",year)
        sub (/,.*/,"",year)
    }
    # print "year = " year > "/dev/stderr"
}

# <b>Years:</b> 2019            </p>
# <b>Years:</b> 2014 - 2023            </p>
/<b>Years:</ {
    lastLineNum = NR
    split ($0,fld,"[<>]")

    # This should be the last line of every movie.
    # So finish processing and add line to spreadsheet

    # "The Moonstone" needs to be revised to avoid duplicate names
    if (title == "The Moonstone") {
        if (contentId == "FS_b0824cbr") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'The Moonstone (2016)'\n",
                    title) >> ERRORS
            title = "The Moonstone (2016)"
        }
    }

    # "Porridge" needs to be revised to avoid duplicate names
    if (title == "Porridge") {
        if (contentId == "b006m9kn") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Porridge (1974-1977)'\n",
                    title) >> ERRORS
            title = "Porridge (1974-1977)"
        } else if (contentId == "p05dsmwl") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'Porridge (2016-2017)'\n",
                    title) >> ERRORS
            title = "Porridge (2016-2017)"
        }
    }
    # print "==> title = " title > "/dev/stderr"
    # print "==> contentId = " contentId > "/dev/stderr"

    # Save titles for use in BBox_uniqTitles
    print title >> RAW_TITLES
    # print "title = " title > "/dev/stderr"

    # Turn title into a HYPERLINK
    fullTitle = "=HYPERLINK(\"" full_URL "\";\"" title "\")"
    # print "fullTitle = " fullTitle > "/dev/stderr"

    # Print a spreadsheet line
    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
            fullTitle, numSeasons, numEpisodes, duration,
            genre, year, rating, description)
    printf ("%s\t%s\t%s\t%s\t%s\t%s\t%s\t",
            contentType, contentId, showType, dateType,
            originalDate, seasonNumber, episodeNumber)
    printf ("%d\t%d\n", firstLineNum, lastLineNum)
}

END {
    printf ("In getBBoxShowsFromHTML.awk \n") > "/dev/stderr"

    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    printf ("    Processed %d %s\n", totalShows, pluralShows) > "/dev/stderr"

    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf ("%8d %s revised in %s\n",
                revisedTitles, plural, FILENAME) > "/dev/stderr"
    }
}
