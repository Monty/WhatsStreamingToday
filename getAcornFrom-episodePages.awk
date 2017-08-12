# Generate an episode description from an Acorn episode file and check for duplicates
#
# INVOCATION:
#       curl -sS --config $EPISODE_CURL_FILE \
#           | awk -v EPISODE_DESCRIPTION_FILE=$EPISODE_DESCRIPTION_FILE \
#           -v ERROR_FILE=$ERROR_FILE -v EPISODE_CURL_FILE=$EPISODE_CURL_FILE \
#           -v EPISODE_NUMBER=$episodeNumber -f getAcornFrom-episodePages.awk
#
# INPUT:
#       <meta itemprop="description" content="Still riddled with guilt after a shooting, \
#       seasoned police officer Nick Barron ... initiates an internal investigation." />
# ---
#       <meta itemprop="numberOfEpisodes" content="1" />
# ---
#       Served from: acorn.tv @ 2017-08-05 20:49:53 by W3 Total Cache
#
# OUTPUT:
#       $EPISODE_DESCRIPTION_FILE
#

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
    next
}

# Extract series with only one episode
/<meta itemprop="numberOfEpisodes" content="1"/ {
    singleEpisode = "yes"
    next
}

# When we get to the bottom of the episode
/^ Served from:/ {
    printf ("%s\n", episodeDescription) >> EPISODE_DESCRIPTION_FILE
    #
    # Grab the URL from the EPISODE_CURL_FILE - you can't dig it out from here
    cmd = "cat -n " EPISODE_CURL_FILE " | grep ' " EPISODE_NUMBER "\t'"
    #
    # Warn about empty descriptions
    if (episodeDescription == "") {
        while ((cmd | getline url) > 0)
            print "==> No description: " url >> ERROR_FILE
        close (cmd)
    }
    episodeDescription = ""
    #
    # Warn about series with only one episode
    if (singleEpisode != "") {
        while ((cmd | getline url) > 0)
            print "==> Only one episode: " url >> ERROR_FILE
        close (cmd)
    }
    singleEpisode = ""
    #
    # Get ready for next episode
    EPISODE_NUMBER += 1
}
