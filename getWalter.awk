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
    htmlFile = showTitle
    gsub(/[[:punct:]]/, "", htmlFile)
    gsub(/ /, "_", htmlFile)
    htmlFile = htmlFile ".html"
    printf("%s\t%s\t%s\n", showURL, showTitle, htmlFile)
}
