# Process data from getWalter.js, PBS-only.csv, and env-show.js

/data-title="/ {
    split ($0,fld,"\"")
    showTitle = fld[2]
}

/data-show-slug=/ {
    split ($0,fld,"\"")
    showSlug = "https://www.pbs.org/show/" fld[2]
    printf ("%s\t%s\n", showSlug, showTitle)
}

/^https:/ {
    split ($0,fld,"\t")
    showTitle = fld[2]
    showURL = fld[1]
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    print showLink
}
