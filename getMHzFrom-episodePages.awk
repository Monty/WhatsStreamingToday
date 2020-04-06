# Generate a separate file with a line for each episode containing
# seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
# episodeTitle, episodeDuration, & episodeDescription with the same columns
# as the primary spreadsheet so they can be combined into one.
# Add to the number of episodes but with no terminating newline
#
# INVOCATION:
#       curl -s https://watch.mhzchoice.com/a-french-village/season:1 \
#           | awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$lastRow \
#           -v NUM_EPISODES_FILE=$NUM_EPISODES_FILE -v ERROR_FILE=$ERROR_FILE \
#           -f getMHzFrom-episodePages.awk
#
# INPUT:
#        <title>A French Village - MHz Choice</title>
#  ---
#        <meta name="apple-itunes-app" content="app-id=1096194231, \
#        app-argument=https://watch.mhzchoice.com/detective-montalbano?page=2">
#  ---
#        <h2 class="site-font-secondary-color site-font-primary-family content-label \
#        padding-top-medium grid-padding-right">
#          18 Episodes
#        </h2>
#  ---
#        <div class="duration-container is-locked">47:58</div>
#  ---
#        <a href="https://watch.mhzchoice.com/a-french-village/season:1/videos/the-landing\
#       -june-12-1940"><strong title="The Landing (June 12, 1940)">The Landing (June 12, 1940)\
#       </strong></a>
#  ---
#        <h4 class="transparent"><span class='media-identifier media-episode'>Episode 1</span> </h4>
#        <div class="transparent padding-top-medium">
#        <p>A doctor oversees the birth of a child. Directed by Phillipe Triboit, 2009.</p>
#
#        <p>This episode will be made available on August 8.</p>
#        </div>
# OUTPUT:
#       $EPISODE_INFO_FILE & the number of episodes
#

# Extract whether this is a page 2
/<meta name="apple-itunes-app" content=".*?page=2">/ {
    page2 = "yes"
}

# Extract only the number of episodes, print them with no terminating newline
# but if this is page 2 skip to avoid double counting
/<h2 class=.*content-label/,/ Episode/ {
    sub (/^ */,"")
    if ($0 ~ / Episode/) {
        if (page2 != "yes")
            printf ("+%d", $1) >> NUM_EPISODES_FILE
        next
    }
}

# Extract the series title
/<title>/ {
    sub (/.*<title>/,"")
    sub (/ - MHz Choice<.*/,"")
    gsub (/&#x27;/,"'")
    gsub (/&quot;/,"\"\"")
    gsub (/&amp;/,"\\&")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    seriesTitle = $0
    next
}

# Extract the duration
/<div class="duration-container/ {
    split ($0,fld,"[<>]")
    episodeDuration = fld[3]
    gsub (/ /,"",episodeDuration)
    # Spreadsheets decipher 2 part durations as time-of-day so make sure they're 3 parts
    if (split (episodeDuration, tm, ":") == 2)
        episodeDuration = "00:" episodeDuration
    next
}

# Extract the episode URL, the episode type, the episode title, and the seasonNumber
/<strong title="/ {
    gsub (/&#x27;/,"'")
    split ($0,fld,"\"")
    episodeURL = fld[2]
    if (episodeURL ~ /-c-.[[:digit:]]{3,4}$/)
        episodeNumberFromURL = substr (episodeURL, length(episodeURL)-1, 2) + 0
    shortURL = episodeURL
    sub (/.*watch/,"watch",shortURL)
    # Default episodeType to "E"
    episodeType = "E"
    # If episode is a BONUS:, set episodeType to "X"
    if (episodeURL ~ /-c-x[[:digit:]]{3,4}$|montme-c-01001|richard-sammel-inetrview/)
        episodeType = "X"
    # Take care of extra fields introduced in February 2020
    titleString = substr ($0, match ($0, /strong title/))
    split (titleString,fld,"\"")
    episodeTitle = fld[2]
    if (episodeTitle ~ /^PR \|/) {
        # Episode is a Trailer (i.e. First look), set episodeType to "T"
        episodeType = "T"
        printf ("-1") >> NUM_EPISODES_FILE
        # print episodeTitle "\t" shortURL >> ERROR_FILE
    }
    #
    # If start of episodeTitle == seriesTitle ": ", remove the redundant part.
    if ((match (episodeTitle, seriesTitle ": ")) == 1) {
        episodeTitle = substr(episodeTitle, RLENGTH + 1)
    }
    gsub (/&quot;/,"\"\"",episodeTitle)
    gsub (/&amp;/,"\\&",episodeTitle)
    sub (/.*season:/,"")
    sub (/\/.*/,"")
    seasonNumber = $0
    next
}

# Extract the episode number, and correct if necessary
# Detective Montalbano requires special processing for page 2 episodeNumber
/<h4 class="/ {
    episodeNumber = $0
    sub (/.*Episode /,"",episodeNumber)
    sub (/<\/span>.*/,"",episodeNumber)
    episodeNumber = episodeNumber + 0
    if (seriesTitle == "Detective Montalbano" && page2 == "yes") {
        oldEpisodeNumber = episodeNumber
        episodeNumber += 24
        printf ("==> Changed E%02d to %s%02d: %s\n", oldEpisodeNumber, episodeType, \
                episodeNumber, shortURL) >> ERROR_FILE
    }
}

# WARNING - other scripts depend on the number and order of the fields below
# Extract the episode description and print the composed info
/<h4 class="transparent"><span class=/,/<\/div>/ {
    if ($0 ~ /<h4 class="transparent"><span class=/) {
        if (episodeNumber == 0) {
            if (episodeNumberFromURL != 0) {
                printf ("==> Changed %s00 to %s%02d: %s\n", episodeType, episodeType, 
                        episodeNumberFromURL, shortURL) >> ERROR_FILE
                episodeNumber = episodeNumberFromURL
            } else {
                printf ("==> Episode number is 00: %s\n", shortURL) >> ERROR_FILE
            }
        }
        printf ("%d\t=HYPERLINK(\"%s\";\"%s, S%02d%s%02d, %s\"\)\t\t\t%s\t\t\t\t\t", \
                SERIES_NUMBER, episodeURL, seriesTitle, seasonNumber, episodeType, episodeNumber, \
                episodeTitle, episodeDuration) >> EPISODE_INFO_FILE
        # Need to account for multiple lines of description
        descriptionLinesFound = 0
        episodeDescription = ""
        # make sure there is no carryforward
        episodeNumber = ""
        episodeNumberFromURL = ""
    }
    if ($0 ~ /<p>/) {
        split ($0,fld,"[<>]")
        paragraph = fld[3]
        gsub (/&quot;/,"\"",paragraph)
        gsub (/&amp;/,"\\&",paragraph)
        # Could be in multiple paragraphs
        descriptionLinesFound += 1
        episodeDescription = episodeDescription (descriptionLinesFound == 1 ? "" : " ") paragraph
    }
    if ($0 ~ /<\/div>/) {
        if (episodeDescription == "") {
            if (episodeType == "T") {
                episodeDescription = episodeTitle
            } else {
                print "==> No description: " shortURL >> ERROR_FILE
            }
        }
        sub (/^PR \| /,"",episodeDescription)
        print episodeDescription >> EPISODE_INFO_FILE
    }
}
