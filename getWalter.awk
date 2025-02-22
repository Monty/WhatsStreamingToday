# Process data from getWalter.js and PBS-only.csv
# Produce a list of show URLs with their Titles

# First save the URL
/ {24}href="\/show\// {
    split($0, fld, "\"")
    showURL = "https://www.pbs.org" fld[2]
}

/ {26}alt="/ {
    split($0, fld, "\"")
    showTitle = fld[2]
    sub(/&amp;/, "\\&", showTitle)
    yamlFile = showTitle
    gsub(/[[:punct:]]/, "", yamlFile)
    gsub(/ /, "_", yamlFile)
    yamlFile = yamlFile ".yaml"
    printf("%s\t%s\t%s\n", showURL, showTitle, yamlFile)
}
