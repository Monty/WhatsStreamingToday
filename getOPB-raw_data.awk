# Process data from getOPB-raw_data.js
function clearShowVariables() {
    # Make sure there is no carryover
    showURL = ""
    showTitle = ""
    showDescription = ""
    showDescriptionLinesFound = 0
    showGenre = ""
    showGenreLinesFound = 0
    numberOfSeasons = 0
}

# Fix single quoted links by removing the first and last characters
#    - 'link "Central Florida Roadtrip: Hemingway in Florida"'
# Also fix escaped double quotes
#    - 'link "Central Florida Roadtrip Street Smarts: \"Presidents\""'
/ {4}- 'link "/ {
    sub(/'link/, "link", $0)
    sub(/':$/, "", $0)
    sub(/'$/, "", $0)
    gsub(/\\"/, "\"", $0)
}

/ {2}- 'heading "/ {
    sub(/'heading/, "heading", $0)
    sub(/':$/, "", $0)
    sub(/'$/, "", $0)
}

# Desired show data
# ==> New File
# showURL
# showTitle
# showDescription
# numberOfSeasons

# Extract tabName from <!-- header lines
/-- .* data from https:/ {
    split($0, fld, " ")
    tabName = fld[2]

    if (tabName == "Main") { print "==> New File" }

    if (tabName == "Specials") { tabName = "Special" }

    print "tabName: " tabName
    phase = tabName

    numFields = split($0, fld, "\"")

    if (numFields == 5) {
        seasonName = fld[2]
        numberOfSeasons = fld[4]
    }
    else {
        seasonName = "Season 1"
        numberOfSeasons = 1
    }

    # Always print numberOfSeasons and specified or default seasonName
    print "numberOfSeasons: " numberOfSeasons
    print "seasonName: " seasonName
}

#<!-- Main page data from https://www.pbs.org/show/expedition/ -->
/-- Main page data from https:/ {
    # Make sure there is no carryover
    clearShowVariables()

    showURL = $0
    sub(/.*https:/, "https:", showURL)
    sub(/ .*/, "", showURL)
    print "showURL: " showURL
    # Create shorter URL by removing https://www.
    shortURL = showURL
    sub(/.*pbs.org/, "pbs.org", shortURL)
    next
}

#  - heading "Astrid" [level=1]:
/^ {2}- heading "/ && phase == "Main" {
    split($0, fld, "\"")
    showTitle = fld[2]
    gsub(/\\"/, "\"", showTitle)
    print "showTitle: " showTitle
    next
}

#  - paragraph: Astrid Nielsen works in the library...
#  showDescriptions are only indented two spaces
#  episodeDescriptions are indented four spaces
/^ {2}- paragraph: / && phase == "Main" {
    showDescriptionLinesFound++
    showDescription = $0
    sub(/^  - paragraph: /, "", showDescription)
    gsub(/\\"/, "\"", showDescription)
    print "showDescription: " showDescription
    next
}

#<!-- About tab data from https://www.pbs.org/show/expedition/ -->
/^ {6}- link "/ && phase == "About" {
    showGenreLinesFound++
    split($0, fld, "\"")
    showGenre = fld[2]
    print "showGenre: " showGenre
    next
}

#<!-- ... tab data from https://www.pbs.org/show/expedition/ -->
#    - link "Osceola County"
/^ {4}- link "/ && phase != "Main" && phase != "About" {
    # print "link = " $0 > "/dev/stderr"
    episodeTitle = substr($0, 13)
    sub(/"$/, "", episodeTitle)
    sub(/":$/, "", episodeTitle) # new format after 250901
    gsub(/\\"/, "\"", episodeTitle)
    # print "episodeTitle = " episodeTitle > "/dev/stderr"
    print "episodeTitle: " episodeTitle
    next
}

/^\/video\// && phase != "Main" && phase != "About" {
    episodeURL = $0
    print "episodeURL: " episodeURL
    next
}

/^ {2}- paragraph: / && phase != "Main" && phase != "About" {
    episodeDescription = $0
    sub(/^  - paragraph: /, "", episodeDescription)
    gsub(/\\"/, "\"", episodeDescription)
    print "episodeDescription: " episodeDescription
    print "--EOE--"
    next
}

END {
    # Leave blank line beetween files
    print "--EOS--"
    print ""

    if (showTitle == "") {
        printf("==> No show title found: %s\n", shortURL) >> ERRORS
    }

    if (showDescriptionLinesFound > 1) {
        printf(\
            "==> %s show descriptions found: %s '%s'\n",
            showDescriptionLinesFound,
            shortURL,
            showTitle\
        ) >> ERRORS
    }

    if (showDescriptionLinesFound == 0) {
        printf(\
            "==> No show descriptions found: %s '%s'\n", shortURL, showTitle\
        ) >> ERRORS
    }

    if (showGenreLinesFound == 0) {
        printf(\
            "==> No show genre found: %s '%s'\n", shortURL, showTitle\
        ) >> ERRORS
    }
}
