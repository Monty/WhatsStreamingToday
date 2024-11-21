# Process data from getWalter.js and PBS-only.csv
# Produce a list of show URLs with their Titles
/href="/ {
    split($0, fld, "\"")
    showURL = "https://www.pbs.org" fld[2]
}

/alt="/ {
    split($0, fld, "\"")
    showTitle = fld[2]
    sub(/&amp;/, "\\&", showTitle)
    printf("%s\t%s\n", showURL, showTitle)
}
