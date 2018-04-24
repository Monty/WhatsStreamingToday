# Build scraper JSON files with a list of individual movies and/or shows to scrape

# INVOCATION
#    awk -v EPISODES_JSON_FILE=$EPISODES_JSON_FILE -v SEASONS_JSON_FILE=$SEASONS_JSON_FILE \
#        -f buildBBoxScrapersFrom-webscraper.awk

BEGIN {
    FS = "\""
}

/\/us\/movie\// {
    numMovies += 1
    shortURL = $6
    printf ("%s    \"https://www.britbox.com%s\"", trailingEpisodesComma, shortURL) \
        >> EPISODES_JSON_FILE
    trailingEpisodesComma = ",\n"
}

/\/us\/show\// {
    numShows += 1
    shortURL = $6
    printf ("%s    \"https://www.britbox.com%s\"", trailingEpisodesComma, shortURL) \
        >> EPISODES_JSON_FILE
    trailingEpisodesComma = ",\n"
    printf ("%s    \"https://www.britbox.com%s\"", trailingSeasonsComma, shortURL) \
        >> SEASONS_JSON_FILE
    trailingSeasonsComma = ",\n"
}

END {
    print "" >> EPISODES_JSON_FILE
    print "" >> SEASONS_JSON_FILE
    print "==> Found " numMovies " movies"
    print "==> Found " numShows " shows"
}
