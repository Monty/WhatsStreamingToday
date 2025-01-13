# Grab fields from preprocessed Walter Presents HTML files
#
# Title  Seasons  Episodes  Duration  Genre  Language  Rating  Description

# These functions are used to shorten code in show and episode processing
function computeEpisodeDuration() {
    # Leading spaces have been deleted in episode logic
    # print "==> episodeHMS = " episodeHMS > "/dev/stderr"
    numFields = split(episodeHMS, tm, " ")

    # Initialize fields to 0 in case any are missing
    secs = mins = hrs = 0

    # Grab hrs, mins, secs
    for (i = 1; i <= numFields; ++i) {
        if (tm[i] ~ /s/) {
            sub(/s/, "", tm[i])
            secs = tm[i]
        }

        if (tm[i] ~ /m/) {
            sub(/m/, "", tm[i])
            mins = tm[i]
        }

        if (tm[i] ~ /h/) {
            sub(/h/, "", tm[i])
            hrs = tm[i]
        }
    }

    # make sure we don't include time for clips
    if (episodeClass != "clip") {
        # Add time to curent show
        showSecs += secs
        showMins += mins + int(showSecs / 60)
        showHrs += hrs + int(showMins / 60)
        showSecs %= 60
        showMins %= 60

        # Add time to total time
        totalTime[3] += secs
        totalTime[2] += mins + int(totalTime[3] / 60)
        totalTime[1] += hrs + int(totalTime[2] / 60)
        totalTime[3] %= 60
        totalTime[2] %= 60
    }

    # Make episodeDuration a string
    episodeDuration = sprintf("%02d:%02d:%02d", hrs, mins, secs)
    # print episodeDuration > "/dev/stderr"
}

function clearEpisodeVariables() {
    # Make sure there is no carryover
    episodeTitle = ""
    episodeURL = ""
    episodeDuration = ""
    episodeLink = ""
    episodeDescription = ""
}

function clearShowVariables() {
    # Make sure there is no carryover
    showURL = ""
    showLanguage = "English"
    showTitle = ""
    showLink = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    numberOfSeasons = 0
    numberOfClipSeasons = 0
    showDuration = ""
    showDescription = ""
    showGenre = ""
    #
    episodeType = "E"
    episodeClass = "episode"
    target_sheet = LONG_SPREADSHEET
    episodeNumber = 0
    clipsEpisodeNumber = 0
    specialsEpisodeNumber = 0
    #
    episodeLinesFound = 0
    seasonLinesFound = 0
    clipLinesFound = 0
    descriptionLinesFound = 0
    genreLinesFound = 0
    durationLinesFound = 0
    #
    seasonNumber = ""
}

function removeHeader() {
    if (match($0, /: /)) { $0 = substr($0, RSTART + 2) }
}

## Start of "Show" processing section
/^showURL: / {
    # Process new show
    # Make sure there is no carryover
    clearShowVariables()
    #
    removeHeader()
    totalShows += 1
    showURL = $0
    # print "==> showURL = " showURL > "/dev/stderr"

    # Create shorter URL by removing https://
    shortShowURL = showURL
    sub(/.*pbs.org/, "pbs.org", shortShowURL)
    next
}

/^showTitle: / {
    removeHeader()
    showTitle = $0
    # gsub(/u0026/, "\\&", showTitle)

    # Modify some show names
    if (shortShowURL ~ /before-we-die/) { showTitle = "Before We Die (Swedish)" }

    if (shortShowURL ~ /before-we-die-uk/) { showTitle = "Before We Die (British)" }

    if (shortShowURL ~ /expedition/) {
        showTitle = "Expedition with Steve Backshall"
    }

    if (shortShowURL ~ /miss-scarlet-duke/) {
        showTitle = "Miss Scarlet and The Duke"
    }

    if (shortShowURL ~ /modus/) { showTitle = "Modus" }

    if (shortShowURL ~ /professor-t/) { showTitle = "Professor T (Belgian)" }

    if (shortShowURL ~ /professor-t-uk/) { showTitle = "Professor T (British)" }

    print showTitle >> RAW_TITLES
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    # print "==> showLink = " showLink > "/dev/stderr"
    next
}

/ with English subtitles/ {
    split($0, fld, " ")
    showLanguage = $(NF - 3)
    # print "==> showLanguage = " showLanguage > "/dev/stderr"
}

/^showDescription: / {
    removeHeader()
    descriptionLinesFound++
    showDescription = $0
    # gsub(/u0026/, "\\&", showDescription)
    # gsub(/&#x27;/, "'", showDescription)
    # gsub(/&quot;/, "\"", showDescription)
    sub(/ with English subtitles/, "", showDescription)
    sub(/ From Walter Presents, in/, " In", showDescription)
    # print "==> showDescription = " showDescription > "/dev/stderr"
    next
}

/^showGenre: / {
    removeHeader()
    genreLinesFound++
    showGenre = $0
    next
}

### Start of tab processing section
/^tabName: Episodes/ {
    episodeType = "E"
    episodeClass = "episode"
    target_sheet = LONG_SPREADSHEET
}

/^tabName: Clips/ {
    # print "==> Clip or Preview " $0 > "/dev/stderr"
    episodeType = "X"
    episodeClass = "clip"
    target_sheet = EXTRA_SPREADSHEET
}

/^tabName: Special/ {
    # print "==> Special episode " $0 > "/dev/stderr"
    episodeType = "X"
    episodeClass = "special"
    target_sheet = LONG_SPREADSHEET
}

/^seasonName: Season [0-9]{1,4}/ {
    removeHeader()
    split($0, fld, " ")
    seasonNumber = fld[2]
    episodeNumber = 0
    clipsEpisodeNumber = 0
    specialsEpisodeNumber = 0
    next
}

/^seasonName: More Clips/ {
    # Use "9999" as a kludge numeric season number
    # It's easier to change to the non-numeric "SMore" using sd
    seasonNumber = "9999"
    clipsEpisodeNumber = 0
    next
}

/^numberOfSeasons: / {
    removeHeader()

    if (episodeClass != "clip") { numberOfSeasons = $0 }
    else { numberOfClipSeasons = $0 }

    # print "==> numberOfSeasons = " numberOfSeasons > "/dev/stderr"
    if (numberOfSeasons <= 0) {
        print "==> showTitle = " showTitle > "/dev/stderr"
        print "    shortShowURL = " shortShowURL > "/dev/stderr"
        print "    numberOfSeasons = " numberOfSeasons > "/dev/stderr"
    }

    next
}

### Start of "Episode" processing section
# Episode processing: Titles
/^episodeTitle: / {
    # Process new episode
    # Make sure there is no carryover
    clearEpisodeVariables()
    #
    removeHeader()
    episodeTitle = $0
    sub(/ \| Superabundant$/, "", episodeTitle)
    # Clean up episodeTitle
    # gsub(/u0026/, "\\&", episodeTitle)
    gsub(/"/, "\"\"", episodeTitle)
    # print "==> episodeTitle = " episodeTitle > "/dev/stderr"
    next
}

# episodeURL: /video/parks-of-the-past-a5hmiu/
# https://www.pbs.org/video/puzzle-eesinx/
# Episode processing: URLs
/^episodeURL: / {
    removeHeader()
    shortEpisodeURL = "pbs.org" $0
    episodeURL = "https://www.pbs.org" $0
    # print "==> episodeURL = " episodeURL > "/dev/stderr"
    next
}

# Episode processing: Descriptions, Durations, and Episode Numbers
# episodeDescription: S13 Ep1305 | Pati saddles
# episodeDescription: "S8 Ep809 | Mocorito
# episodeDescription: Ep1 | Discover
/^episodeDescription: / {
    removeHeader()

    # Extract episode duration
    episodeDescription = $0
    # Clean up episodeDescription
    # gsub(/u0026/, "\\&", episodeDescription)
    # sub(/^> /, "", episodeDescription)
    # sub(/ $/, "", episodeDescription)
    # sub(/&amp;/, "\\&", episodeDescription)
    # gsub(/&#x27;/, "'", episodeDescription)
    # gsub(/&quot;/, "\"", episodeDescription)
    # print "==> episodeDescription = " episodeDescription > "/dev/stderr"

    # Extract episode duration
    numfields = split(episodeDescription, fld, "[()]")
    episodeHMS = fld[numfields - 1]
    # print "episodeHMS = " episodeHMS > "/dev/stderr"
    computeEpisodeDuration()
    # print episodeDuration > "/dev/stderr"
    durationLinesFound++

    if (episodeClass != "clip") {
        episodeLinesFound++
        totalEpisodes++
    }
    else {
        clipLinesFound++
        totalClips++
    }

    # Figure out any specific episode number
    if ($0 ~ /Ep[0-9]{1,4} \|/) {
        split($0, fld, "|")
        episodeField = fld[1]
        # print "episodeField = " episodeField > "/dev/stderr"
        sub(/ $/, "", episodeField)
        sub(/^.*Ep/, "", episodeField)
        sub(/ \|.*/, "", episodeField)

        if (episodeClass != "clip") { episodeNumber = episodeField }
        else { clipsEpisodeNumber = episodeField }

        # print "episodeNumber = " episodeNumber > "/dev/stderr"
    }
    else {
        # It's a generic episode
        if (episodeClass == "clip") { clipsEpisodeNumber++ }

        if (episodeClass == "special") { specialsEpisodeNumber++ }

        if (episodeClass == "episode") { episodeNumber++ }
    }

    next
}

### Wrap up episode
/^--EOE--$/ {
    if (episodeClass == "clip") { episodeNumber = clipsEpisodeNumber }

    if (episodeClass == "special") { episodeNumber = specialsEpisodeNumber }

    # Special case for episodeNumbers that include season number
    if (episodeNumber + 0 >= seasonNumber * 100) {
        episodeNumber = episodeNumber - seasonNumber * 100
    }

    # print "episodeNumber = \"" episodeNumber "\"" > "/dev/stderr"
    if (length(episodeNumber) < 4) {
        episodeNumber = sprintf("%02d", episodeNumber)
    }

    episodeLink = sprintf(\
        "=HYPERLINK(\"%s\";\"%s, S%02d%s%s, %s\")",
        episodeURL,
        showTitle,
        seasonNumber,
        episodeType,
        episodeNumber,
        episodeTitle\
    )

    printf(\
        "%s\t\t\t%s\t\t\t\t%s\n",
        episodeLink,
        episodeDuration,
        episodeDescription\
    ) >> target_sheet
    next
}

### End of "Episode" processing section

## Wrap up show
/^--EOS--$/ {
    if (numberOfSeasons <= 0) {
        printf(\
            "==> No seasons found: %s '%s'\n", shortShowURL, showTitle\
        ) >> ERRORS
    }

    if (seasonNumber + 0 >= 100) {
        printf(\
            "==> Season number %d in %s\n", seasonNumber, shortShowURL\
        ) >> ERRORS
    }

    if (episodeLinesFound == 0) {
        printf(\
            "==> No episodes found: %s '%s'\n", shortShowURL, showTitle\
        ) >> ERRORS
    }

    if (episodeLinesFound == 1) {
        printf(\
            "==> Only one episode: %s '%s'\n", shortShowURL, showTitle\
        ) >> ERRORS
    }

    if (descriptionLinesFound == 0) {
        printf(\
            "==> No description found: %s '%s'\n", shortShowURL, showTitle\
        ) >> ERRORS
    }

    if (genreLinesFound == 0) {
        printf(\
            "==> No genre found: %s '%s'\n", shortShowURL, showTitle\
        ) >> ERRORS
    }

    if (durationLinesFound == 0) {
        printf(\
            "==> No durations found: %s '%s'\n", shortShowURL, showTitle\
        ) >> ERRORS
    }

    # Fix any known issues
    if (showTitle == "La Otra Mirada" && showLanguage != "Spanish") {
        printf("==> Setting '%s' language to Spanish\n", showTitle) >> ERRORS
        showLanguage = "Spanish"
    }

    if (showTitle == "Superabundant" && genreLinesFound == 0) {
        printf("==> Setting '%s' genre to Food\n", showTitle) >> ERRORS
        showGenre = "Food"
    }

    showDuration = sprintf("%02dh %02dm", showHrs, showMins)
    totalSeasons += numberOfSeasons

    printf(\
        "%s\t%s\t%s\t%s\t%s\t%s\t\t%s\n",
        showLink,
        numberOfSeasons,
        episodeLinesFound,
        showDuration,
        showGenre,
        showLanguage,
        showDescription\
    )

    if (episodeLinesFound >= 1) {
        printf(\
            "%s\t%s\t%s\t\t%s\t%s\t\t%s\n",
            showLink,
            numberOfSeasons,
            episodeLinesFound,
            showGenre,
            showLanguage,
            showDescription\
        ) >> LONG_SPREADSHEET
    }

    # Add clips header for EXTRA_SPREADSHEET
    if (clipLinesFound >= 1) {
        printf(\
            "%s\t%s\t%s\t\t%s\t%s\t\t%s\n",
            showLink,
            numberOfClipSeasons,
            clipLinesFound,
            showGenre,
            showLanguage,
            showDescription\
        ) >> EXTRA_SPREADSHEET
    }
}

## End of "Show" processing section
END {
    printf("%02dh %02dm\n", totalTime[1], totalTime[2]) > DURATION
    printf("In getWalterFrom-raw_data.awk\n") > "/dev/stderr"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    totalClips == 1 ? pluralClips = "clip" : pluralClips = "clips"
    printf(\
        "    Processed %d %s, %d %s, %d %s, %d %s\n",
        totalShows,
        pluralShows,
        totalSeasons,
        pluralSeasons,
        totalEpisodes,
        pluralEpisodes,
        totalClips,
        pluralClips\
    ) > "/dev/stderr"
}
