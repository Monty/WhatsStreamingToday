BEGIN {
    FS="\t"
    print "Sortkey\tTitle\tSeasons\tDuration\tYear\tRating\tDescription"
}

# if needed for debugging record placment, replace "/nosuchrecord/" below
/nosuchrecord/ {
    print ""
    print NR " - " $0
    for ( i = 1; i <= NF; i++ ) {
        print "field " i " = " $i
    }
}

{
    for ( i = 1; i <= NF; i++ ) {
        if ($i == "null")
            $i = ""
    }
}

/\/us\/movie\/|\/us\/show\//{
    URL = $3
    showTitle = $4
    Year = $5
    NumSeasons = $6
    Duration = $7
    Rating = $8
    Description = $9

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
    if (match (showTitle, /^The /))
        showTitle = substr(showTitle, 5) ", The"

    # Indicate different types of programs
    showtype = "S"
    if (URL ~ /^\/us\/movie\//)
        showtype = "M"

    # Extract sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("%s%05d", showtype, fld[nflds])
        printf \
            ("%s - %s\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s\"\)\t%s\t%s\t%s\t%s\t%s\n",\
             showTitle, sortkey, URL, showTitle, NumSeasons, HMS, Year, Rating, Description)
    }
}
