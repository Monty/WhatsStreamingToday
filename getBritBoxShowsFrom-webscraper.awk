# Print the processed "Episode" lines from a WebScraper csv file saved in tsv format

# Field numbers for movies
#    1 web-scraper-order  2 web-scraper-start-url  3 Program_Title     4 Year    5 Duration
#    6 Duration           7 Rating                 8 Description

# Field numbers for shows
#    1 web-scraper-order  2 web-scraper-start-url  3 SsnURL     4 SsnURL-href    5 URL
#    6 Program_Title      7 Episode_Title          8 Year       9 Duration      10 Rating
#   11 Description


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

/\/us\/movie\// {
    URL = $2
    showTitle = $3
    NumSeasons = 1
    NumEpisodes = 1
    Year = $4
    Duration = $5
    Rating = $6
    Description = $7

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("M%05d", fld[nflds])
    } else {
        sortkey = "XXXX"
    }

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

    savedLine = sprintf \
        ("%s (1) %s\t=HYPERLINK(\"%s\";\"%s\"\)\t%s\t%s\t%s\t%s\t%s\t%s",\
         showTitle, sortkey, URL, showTitle, NumSeasons, NumEpisodes, HMS, Year,\
         Rating, Description)

    # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
    sub (/^'/,"",savedLine)

    print savedLine
}

/\/us\/episode\// {
    URL = $5
    showTitle = $6
    episodeTitle = $7
    Years = $8
    Duration = $9
    Rating = $10
    Description = $11

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

    savedLine = sprintf \
        ("%s (2) %s %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t\t%s\t%s\t%s\t%s",\
         showTitle, Years, sortkey, URL, showTitle, sortkey, episodeTitle, HMS, Years, \
         Rating, Description)

    # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
    sub (/^'/,"",savedLine)

    print savedLine
}
