# Generate a separate file with a line for each episode containing
# seriesNumber, episodeURL, seriesTitle, seasonNumber, episodeNumber,
# episodeTitle, & episodeDescription with the same columns as the
# primary spreadsheet so they can be combined into one.
# Return the number of episodes but with no terminating newline
#
# INVOCATION:
#       curl -s https://mhzchoice.vhx.tv/a-french-village/season:1 \
#           | awk -v EPISODE_INFO_FILE=$EPISODE_INFO_FILE -v SERIES_NUMBER=$lastRow \
#           -f getMHzFrom-episodePages.awk >>$NUM_EPISODES_FILE
#
# INPUT:
#        <title>A French Village - MHz Choice</title>
#  ---
#              <h2 class="site-font-secondary-color site-font-primary-family content-label padding-top-medium grid-padding-right">
#                18 Episodes
#              </h2>
#  ---
#                <a href="https://mhzchoice.vhx.tv/a-french-village/season:1/videos/the-landing-june-12-1940"><strong title="The Landing (June 12, 1940)">The Landing (June 12, 1940)</strong></a>
#  ---
#              <h4 class="transparent"><span class='media-identifier media-episode'>Episode 1</span> </h4>
#             <div class="transparent padding-top-medium">
#               <p>A doctor oversees the birth of a child. Directed by Phillipe Triboit, 2009.</p>
#             </div>
# OUTPUT:
#       $EPISODE_INFO_FILE & the number of episodes
#

# Extract only the number of episodes, retuen them with no terminating newline
/<h2 class=.*content-label/,/h2>/ {
    sub (/^ */,"")
    if ($0 ~ / Episode/) {
        printf ("+%d", $1)
    }
    if ($0 ~ /h2>/) {
        next
    }
}

# Extract the series title
/<title>/ {
    sub (/.*<title>/,"")
    sub (/ - MHz Choice<.*/,"")
    gsub (/&#x27;/,"'")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    seriesTitle = $0
    next
}

# Extract the episode URL and the episode title
/<strong title="/ {
    gsub (/&#x27;/,"'")
    split($0,fld,"\"")
    episodeURL = fld[2]
    episodeTitle = fld[4]
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

# Extract the episode description and print the composed info
/<div class="transparent padding-top-medium"/,/<\/div>/ {
    if ($0 ~ /<p>/) {
        sub (/.*<p>/,"")
        sub (/<\/p>.*/,"")
        printf ("%d\t=HYPERLINK(\"%s\",\"%s, S%02dE%02d, %s\"\)\t\t\t\t\t\t\t%s\n", \
            SERIES_NUMBER, episodeURL, seriesTitle, seasonNumber, episodeNumber, episodeTitle, \
            $0) >>EPISODE_INFO_FILE
    }
}
