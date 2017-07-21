# Generate a separate file with a line for each episode containing
# seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
# episodeTitle, episodeDuration, & episodeDescription with the same columns
# as the primary spreadsheet so they can be combined into one.
# Add to the number of episodes but with no terminating newline
#
# INVOCATION:
#       curl -s https://mhzchoice.vhx.tv/a-french-village/season:1 \
#           | awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$lastRow \
#           -v NUM_EPISODES_FILE=$NUM_EPISODES_FILE -f getMHzFrom-episodePages.awk
#
# INPUT:
#        <title>A French Village - MHz Choice</title>
#  ---
#        <meta name="apple-itunes-app" content="app-id=1096194231, \
#        app-argument=https://mhzchoice.vhx.tv/detective-montalbano?page=2">
#  ---
#        <h2 class="site-font-secondary-color site-font-primary-family content-label \
#        padding-top-medium grid-padding-right">
#          18 Episodes
#        </h2>
#  ---
#        <div class="duration-container is-locked">47:58</div>
#  ---
#        <a href="https://mhzchoice.vhx.tv/a-french-village/season:1/videos/the-landing\
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
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    seriesTitle = $0
    next
}

# Extract the duration
/<div class="duration-container/ {
    sub (/.*<div class="duration-container.*">/,"")
    sub (/<\/div>/,"")
    gsub (/ /,"")
    episodeDuration = $0
    # Spreadsheets decipher 2 part durations as time-of-day so make sure they're 3 parts
    if (split ($0, tm, ":") == 2)
        episodeDuration = "00:" $0
    next
}

# Extract the episode URL, the episode title, and the seasonNumber
/<strong title="/ {
    gsub (/&#x27;/,"'")
    split ($0,fld,"\"")
    episodeURL = fld[2]
    episodeTitle = fld[4]
    gsub (/&quot;/,"\"\"",episodeTitle)
    sub (/.*season:/,"")
    sub (/\/.*/,"")
    seasonNumber = $0
    next
}

# Extract the episode number
/<h4 class="/ {
    sub (/.*Episode /,"")
    sub (/<\/span>.*/,"")
    episodeNumber = $0
    next
}

# WARNING - other scripts depend on the number and order of the fields below
# Extract the episode description and print the composed info
/<div class="transparent padding-top-medium"/,/<\/div>/ {
    if ($0 ~ /<div class="transparent padding-top-medium"/) {
        printf ("%d\t=HYPERLINK(\"%s\";\"%s, S%02dE%02d, %s\"\)\t\t\t%s\t\t\t\t\t", \
            SERIES_NUMBER, episodeURL, seriesTitle, seasonNumber, episodeNumber, episodeTitle, \
            episodeDuration) >> EPISODE_INFO_FILE
        # Need to account for multiple lines of description
        descriptionLinesFound = 0
        episodeDescription = ""
    }
    if ($0 ~ /<p>/) {
        sub (/.*<p>/,"")
        sub (/<\/p>.*/,"")
        gsub (/&quot;/,"\"")
        # Could be in multiple paragraphs
        descriptionLinesFound += 1
        episodeDescription = episodeDescription (descriptionLinesFound == 1 ? "" : " ") $0
    }
    if ($0 ~ /<\/div>/) {
        print episodeDescription >> EPISODE_INFO_FILE
    }
}
