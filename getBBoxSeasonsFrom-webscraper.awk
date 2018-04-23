# Print the processed "Season" lines from a WebScraper csv file saved in tsv format

# INVOCATION:
#       awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
#           -f getBBoxSeasonsFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE

# Field numbers
#    1 web-scraper-start-url    2 SsnURL    3 SsnURL-href    4 EpiURL    5 EpiURL-href
#    6 Program_Title            7 Sn_Title  8 Sn_Years       9 Sn_Epis  10 Sn_Description
#   11 More_Description

BEGIN {
    FS="\t"
    OFS="\t"
    print "Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear(s)\tRating\tDescription"
}

{
    for ( i = 1; i <= NF; i++ ) {
        if ($i == "null")
            $i = ""
    }
}

/\/us\/season\// {
    URL = $3
    showTitle = $(NF-5)
    seasonTitle = $(NF-4)
    Years = $(NF-4)
    numEpisodes = $(NF-2)
    moreDescription = $(NF)
    moreDescription == "" ? Description = $(NF-1) : Description = moreDescription

    # Non-existent fields in Seasons
    numSeasons = ""
    HMS = ""
    Rating = ""
    #
    showtype = "S"
    depth = "1"

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_S[[:digit:]]*_[[:digit:]]*$/) {
        seasonNumber = substr(fld[nflds-1], 2)
        sortkey = sprintf ("S%02d", seasonNumber)
    } else {
        sortkey = sprintf ("S%05d", fld[nflds])
    }

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }

    # Build string used in Title URL
    fullTitle = showTitle ", " sortkey ", " seasonTitle

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
    URL = $1
    nflds = split (URL,URLflds,"/")
    print "    " URLflds[nflds]  >> ERROR_FILE
}

END {
    if (badEpisodes > 0 ) {
        badEpisodes == 1 ? field = "URL" : field = "URLs"
        printf ("==> %2d extra /show/ %s in %s\n", badEpisodes, field, FILENAME) > "/dev/stderr"
    }
}
