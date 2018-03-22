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

    sub (/ Season[s]/,"",NumSeasons)
    sub( / min/,"",Duration)

    # Convert duration from minutes to HMS
    secs = 0
    mins = Duration % 60
    hrs = int(Duration / 60)
    HMS = sprintf ("%02d:%02d:%02d", hrs, mins, secs)

    # Titles starting with "The" should not sort based on "The"
    if (match (showTitle, /^The /)) {
        showTitle = substr(showTitle, 5) ", The"
    }
}

/\/us\/movie\// {
    # Extract movie sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("M%05d", fld[nflds])
        printf \
            ("%s %s - mv\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             showTitle, sortkey, URL, showTitle, sortkey, \
             Title, HMS, Year, Rating, Description)
    }
    next
}

/\/us\/show\// {
    # Extract show sortkey from URL
    nflds = split (URL,fld,"_")
    if (URL ~ /_[[:digit:]]*$/) {
        sortkey = sprintf ("S%05d", fld[nflds])
        printf \
            ("%s %s - sh\t=HYPERLINK(\"https://www.britbox.com%s\";\"%s, %s, %s\"\)\t\t%s\t%s\t%s\t%s\n", \
             showTitle, sortkey, URL, showTitle, sortkey, \
             Title, HMS, Year, Rating, Description)
    }
    next
}


