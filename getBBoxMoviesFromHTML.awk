# Produce a movies spreadsheet from TV Movies html

# INVOCATION:
# awk -v ERRORS=$ERRORS -v RAW_TITLES=$RAW_TITLES \
#   -f getBBoxMoviesFromHTML.awk "$TV_MOVIE_HTML" |
#   sort -fu --key=4 --field-separator=\" >"$MOVIES_CSV"

BEGIN {
    # Print spreadsheet header
    printf ("Title\tSeasons\tEpisodes\tDuration\tGenre\tYear\tRating\tDescription\t")
    printf ("Content_Type\tContent_ID\tShow_Type\tDate_Type\tOriginal_Date\t")
    printf ("Sn_#\tEp_#\t1st_#\tLast_#\n")
}

# <title>300 Years of French and Saunders - Comedy | BritBox</title>
/<title>/ {
    # Make sure no fields have been carried over due to missing keys
    title = ""
    fullTitle = ""
    numSeasons = ""
    numEpisodes = ""
    duration = ""
    genre = ""
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

    # print
    firstLineNum = NR
    split ($0,fld,"[<>]")
    title = fld[3]
    sub (/ - .*/,"",title)
    gsub (/&amp;/,"\\&",title)
    gsub (/&#39;/,"'",title)
}

# <meta name="description" content="Comedy dream team Dawn French and Jennifer Saunders reunite for the first time in ten years for a thirtieth-anniversary show bursting mirth, mayhem, And wigs. Lots and lots of wigs." />
# 
# Some descripotions may contain quotes
# 
# <meta name="description" content="Since "A Christmas Carol" was first published   in 1843, the name of Ebenezer Scrooge has been famous throughout the world. See       Michael Hordern&#39;s stunning portrayal of the miserly misanthrope being shown the   error of his ways in this iconic adaptation." />
/<meta name="description" / {
    sub (/.*name="description" content="/,"")
    sub (/" \/>.*/,"")
    description = $0
    gsub (/&amp;/,"\\&",description)
    gsub (/&#160;/," ",description)
    gsub (/&#39;/,"'",description)
    gsub (/&#233;/,"é",description)
    gsub (/&#239;/,"ï",description)
}

# <link rel="canonical" href="https://www.britbox.com/us/movie/300_Years_of_French_and_Saunders_p05wv7gy" />
/<link rel="canonical" / {
    split ($0,fld,"\"")
    full_URL = fld[4]
    # print "full_URL = " full_URL > "/dev/stderr"
}

# "type": "movie",
/"type": "movie"/ {
    contentType = "tv_movie"
    showType = "movie"
    totalMovies += 1
}

# "/movies/genres/Comedy"
/"\/movies\/genres\// {
    split ($0,fld,"\/")
    genre = fld[4]
    sub (/".*/,"",genre)
}

# "code": "TVPG-TV-14",
/"code": "TVPG-/ {
    split ($0,fld,"\"")
    rating = fld[4]
    sub (/TVPG-/,"",rating)
}

# "releaseYear": 2017,
/"releaseYear": / {
    dateType = "releaseYear"
    split ($0,fld,"\"")
    year = fld[3]
    sub (/: /,"",year)
    sub (/,.*/,"",year)
}

# "customId": "p05wv7gy",
/"customId": "/ {
    split ($0,fld,"\"")
    contentId = fld[4]
    # print "contentId = " contentId > "/dev/stderr"
}

# <b>Duration: </b>48 min
/<b>Duration: </ {
    lastLineNum = NR
    split ($0,fld,"[<>]")
    duration = fld[5]
    sub (/ .*/,"",duration)
    duration = "0:" duration
    # print "duration = " duration > "/dev/stderr"

    # This should be the last line of every movie.
    # So finish processing and add line to spreadsheet

    # "A Midsummer Night's Dream" needs to be revised to avoid duplicate names
    if (title == "A Midsummer Night's Dream") {
        if (contentId == "p089tsfc") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'A Midsummer Night's Dream (1981)'\n",
                    title) >> ERRORS
            title = "A Midsummer Night's Dream (1981)"
        } else if (contentId == "p05t7hx2") {
            revisedTitles += 1
            printf ("==> Changed title '%s' to 'A Midsummer Night's Dream (2016)'\n",
                    title) >> ERRORS
            title = "A Midsummer Night's Dream (2016)"
        }
    }

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
    printf ("In getBBoxMoviesFromHTML.awk \n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    printf ("    Processed %d %s\n", totalMovies, pluralMovies) > "/dev/stderr"

    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? plural = "title" : plural = "titles"
        printf ("%8d %s revised in %s\n",
                revisedTitles, plural, FILENAME) > "/dev/stderr"
    }
}
