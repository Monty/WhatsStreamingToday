# Generate an episode description from an Acorn episode file and check for duplicates
#
# INVOCATION:
#       curl -s https://acorn.tv/192/series1/partners \
#           | awk -v EPISODE_DESCRIPTION_FILE=$EPISODE_DESCRIPTION_FILE \
#           -v SERIES_NUMBER=$currentSeriesNumber -f getAcornFrom-episodePages.awk
#
# INPUT:
#       <meta itemprop="description" content="Still riddled with guilt after a shooting, \
#       seasoned police officer Nick Barron ... initiates an internal investigation." />
# ---
#       <meta itemprop="numberOfEpisodes" content="1" />
#
# OUTPUT:
#       $EPISODE_DESCRIPTION_FILE
#

# Extract possible duplicates
/<meta itemprop="numberOfEpisodes" content="1"/ {
    # Generate a unique string we can 'grep -v' to remove duplicates
    possibleDup = sprintf ("\t~~~dup~~~")
    next
}

# Extract the episode description
/<meta itemprop="description" content="/ {
    sub (/.*content="/,"")
    sub (/..\/>/,"")
    # fix sloppy input spacing
    gsub (/ \./,".")
    gsub (/  */," ")
    sub (/ *$/,"")
    # fix funky HTML characters
    gsub (/&lsquo;/,"’")
    gsub (/&rsquo;/,"’")
    episodeDescription = $0
}

END { printf ("%s%s\n", episodeDescription, possibleDup) >> EPISODE_DESCRIPTION_FILE }
