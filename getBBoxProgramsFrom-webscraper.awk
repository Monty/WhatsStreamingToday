# Print processed "Program" lines from a WebScraper csv file saved in tsv format

# INVOCATION:
#       awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v ERROR_FILE=$ERROR_FILE \
#           -f getBBoxEpisodesFrom-webscraper.awk $EPISODES_SORTED_FILE >$EPISODES_SPREADSHEET_FILE

# Field numbers
#    1 URL    2 Program_Title    3 Sn_Years    4 Seasons    5 Description

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

/\/us\/show\// {
    URL = $1
    showTitle = $2
    Years = $3
    numSeasons = $4
    Description = $5

    # Non-existent fields in Programs
    numEpisodes = ""
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

    # Special processing for some shows is needed in all getBBox*From-webscraper.awk scripts.
    # "Changed" message and counting revisedTitles are only in getBBoxProgramsFrom-webscraper.awk
    # so they are not repeated for each episode and each season.
    if (URL ~ /Maigret_15974$/) {
        revisedTitles += 1
        printf ("==> Changed title '%s' to 'Maigret (2016–2017)': www.britbox.com%s\n", \
                showTitle, URL) >> ERROR_FILE
        showTitle = "Maigret (2016–2017)"
    }
    if (URL ~ /Porridge_14747$/) {
        revisedTitles += 1
        printf ("==> Changed title '%s' to 'Porridge (2016-2017)': www.britbox.com%s\n", \
                showTitle, URL) >> ERROR_FILE
        showTitle = "Porridge (2016-2017)"
    }
    if (URL ~ /Porridge_9509$/) {
        revisedTitles += 1
        printf ("==> Changed title '%s' to 'Porridge (1974-1977)': www.britbox.com%s\n", \
                showTitle, URL) >> ERROR_FILE
        showTitle = "Porridge (1974-1977)"
    }

    # Build string used in Title URL
    fullTitle = showTitle

    # Get rid of text in numSeasons
    sub (/ Seasons?/,"",numSeasons)

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
}

END {
    printf ("In getBBoxProgramsFrom-webscraper.awk\n") > "/dev/stderr"
    if (revisedTitles > 0 ) {
        revisedTitles == 1 ? field = "title" : field = "titles"
        printf ("    %2d %s revised in %s\n", revisedTitles, field, FILENAME) > "/dev/stderr"
    }
}
