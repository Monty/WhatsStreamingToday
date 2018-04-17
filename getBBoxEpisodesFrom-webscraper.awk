# Print the processed "Episode" lines from a WebScraper csv file saved in tsv format

# Field numbers
#    1 web-scraper-start-url  2 SsnURL     3 SsnURL-href    4 URL        5 Program_Title
#    6 Episode_Title          7 Year       8 Duration       9 Rating    10 Description


BEGIN {
    FS="\t"
    print "Sortkey\tTitle\tSeasons\tEpisodes\tDuration\tYear(s)\tRating\tDescription"
}

{
    for ( i = 1; i <= NF; i++ ) {
        if ($i == "null")
            $i = ""
    }
}

/\/us\// {
    URL = $4
    showTitle = $5
    episodeTitle = $6
    Years = $7
    Duration = $8
    Rating = $9
    Description = $10

    # Convert duration from minutes to HMS
    sub( / min/,"",Duration)
    secs = 0
    mins = Duration % 60
    hrs = int(Duration / 60)
    HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (HMS == "00:00:00")
        HMS = ""

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /))
        showTitle = substr(showTitle, 5) ", The"
}


/\/us\/movie\// {
    NumSeasons = 1
    NumEpisodes = 1

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("M%05d", fld[nflds])
    } else {
        sortkey = "XXXX"
    }

    savedLine = sprintf \
        ("%s (1) %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s\"\)\t%s\t%s\t%s\t%s\t%s\t%s",\
         showTitle, sortkey, URL, showTitle, NumSeasons, NumEpisodes, HMS, Years,\
         Rating, Description)

    # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
    sub (/^'/,"",savedLine)

    print savedLine
}

/\/us\/episode\// {
    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_S[[:digit:]]*_E[[:digit:]]*_[[:digit:]]*$/) {
        seasonNumber = substr(fld[nflds-2], 2)
        episodeNumber = substr(fld[nflds-1], 2)
        sortkey = sprintf ("S%02dE%02d", seasonNumber, episodeNumber)
    } else {
        sortkey = sprintf ("E%05d", fld[nflds])
    }

    # Get rid of redundant "Series #" or "Series #" from episodeTitle
    if (match (episodeTitle, /^Season [[:digit:]]*, |^Series [[:digit:]]*, /))
        episodeTitle = substr(episodeTitle,RLENGTH+1)

    savedLine = sprintf \
        ("%s (2) %s %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t\t%s\t%s\t%s\t%s",\
         showTitle, Years, sortkey, URL, showTitle, sortkey, episodeTitle, HMS, Years, \
         Rating, Description)

    # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
    sub (/^'/,"",savedLine)

    print savedLine
}
