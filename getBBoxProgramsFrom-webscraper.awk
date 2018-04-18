# Print processed "Program" lines from a WebScraper csv file saved in tsv format

# INVOCATION:
#       awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
#           -f getBBoxEpisodesFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE

# Field numbers
#    1 URL    2 Program_Title    3 Sn_Years    4 Seasons    5 Description

BEGIN {
    FS="\t"
    # print "Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear(s)\tRating\tDescription"
}

{
    for ( i = 1; i <= NF; i++ ) {
        if ($i == "null")
            $i = ""
    }
}

/\/us\/show\// {
    URL = $1
    showTitle = $2
    Years = $3
    NumSeasons = $4
    Description = $5

    # Non-existent fields in Programs
    NumEpisodes = ""
    HMS = ""
    Rating = ""
    #
    showtype = "S"
    depth = "1"

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("%s%05d", showtype, fld[nflds])
    } else {
        sortkey = "XXXX"
    }

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }
    
    # Build string used in Title URL
    fullTitle = showTitle

    # Get rid of text in NumSeasons
    sub (/ Seasons?/,"",NumSeasons)

    # Create spreadsheet row in common format
    savedLine = sprintf \
        ("%s (%s) %s %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s\"\)\t%s\t%s\t%s\t%s\t%s\t%s",\
         showTitle, depth, Years, sortkey, URL, fullTitle, NumSeasons, NumEpisodes, \
         HMS, Years, Rating, Description)

    # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
    sub (/^'/,"",savedLine)

    print savedLine
}
