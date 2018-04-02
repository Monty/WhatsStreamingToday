# Print the processed "Episode" lines from a WebScraper csv file saved in tsv format

# Field numbers
#    1 web-scraper-order  2 web-scraper-start-url  3 PgmURL            4 PgmURL-href       5 SsnURL
#    6 SsnURL-href        7 URL                    8 Program_Title     9 Episode_Title    10 Year
#   11 Duration          12 Rating                13 Description


BEGIN {
    FS="\t"
    print "Sortkey\tTitle\t\tDuration\tYear(s)\tRating\tDescription"
}

{
    for ( i = 1; i <= NF; i++ ) {
        if ($i == "null")
            $i = ""
    }
}

/\/us\/episode\// {
    URL = $7
    showTitle = $8
    episodeTitle = $9
    Years = $10
    Duration = $11
    Rating = $12
    Description = $13

    # Extract sortkey from URL
    URL ~ /^\/us\/movie\// ? showtype = "M" : showtype = "S"
    nflds = split (URL,fld,"_")
    if (URL ~ /_S[[:digit:]]_E[[:digit:]]_[[:digit:]]*$/) {
        seasonNumber = substr(fld[nflds-2], 2)
        episodeNumber = substr(fld[nflds-1], 2)
        sortkey = sprintf ("S%02dE%02d", seasonNumber, episodeNumber)
    } else {
        sortkey = sprintf ("E%05d", fld[nflds])
    }

    sub( / min/,"",Duration)

    # Convert duration from minutes to HMS
    secs = 0
    mins = Duration % 60
    hrs = int(Duration / 60)
    HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
    if (HMS == "00:00:00")
        HMS = ""

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /))
        showTitle = substr(showTitle, 5) ", The"

    printf \
        ("%s (2) %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s,  %s\"\)\t\t%s\t%s\t%s\t%s\n",\
         showTitle, sortkey, URL, showTitle, sortkey, episodeTitle, HMS, Years, Rating, Description)
}
