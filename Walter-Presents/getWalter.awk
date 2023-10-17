# Process data from getWalter.js and PBS-only.csv
# Produce a list of show URLs with their Titles

/data-title="/ {
    split ($0,fld,"\"")
    showTitle = fld[2]
    sub (/&amp;/,"\\&",showTitle)
}

/data-show-slug=/ {
    split ($0,fld,"\"")
    showURL = "https://www.pbs.org/show/" fld[2] "/"
    printf ("%s\t%s\n", showURL, showTitle)
}
