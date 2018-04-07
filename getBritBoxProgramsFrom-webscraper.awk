# Print processed "Program" lines from a WebScraper csv file saved in tsv format

# Field numbers
#    1 web-scraper-order  2 web-scraper-start-url  3 URL        4 Program_Title   5 Sn_Years
#    6 Seasons            7  Mv_Year               8  Duration  9  Rating        10  Description

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

/\/us\/movie\/|\/us\/show\// {
    URL = $3
    showTitle = $4
    $7  == "" ? Year = $5 : Year = $7
    NumSeasons = $6
    Duration = $8
    Rating = $9
    Description = $10

    sub (/ Seasons?/,"",NumSeasons)
    sub( / min/,"",Duration)

    # Convert duration from minutes to HMS
    secs = 0
    mins = Duration % 60
    hrs = int(Duration / 60)
    HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (HMS == "00:00:00")
        HMS = ""

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        print "==> Rearranged: " showTitle >> ERROR_FILE
        showTitle = substr(showTitle, 5) ", The"
    }

    # Indicate different types of programs
    URL ~ /^\/us\/movie\// ? showtype = "M" : showtype = "S"

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("%s%05d", showtype, fld[nflds])
        savedLine = sprintf \
            ("%s (1) %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s\"\)\t%s\t\t%s\t%s\t%s\t%s",\
             showTitle, sortkey, URL, showTitle, NumSeasons, HMS, Year, Rating, Description)

        # Make sure line doesn't start with a single quote so it sorts correctly in Open Office
        sub (/^'/,"",savedLine)

        print savedLine
    }
}
