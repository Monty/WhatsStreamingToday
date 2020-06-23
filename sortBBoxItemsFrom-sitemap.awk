# Rearrange a raw BritBox Catalog (apple_catalogue_feed.xml) so items are sorted by contentType

# INVOCATION
#   awk -v ERROR_FILE=$ERROR_FILE -v TV_MOVIE_ITEMS=$TV_MOVIE_ITEMS -v TV_SHOW_ITEMS=$TV_SHOW_ITEMS \
#       -v TV_SEASON_ITEMS=$TV_SEASON_ITEMS -v TV_EPISODE_ITEMS=$TV_EPISODE_ITEMS \
#       -f sortBBoxItemsFrom-sitemap.awk $SITEMAP_FILE

# Add inclusive content of <item .. item> to a string
/<item contentType="/,/<\/item>/ {
    wholeItem = wholeItem $0 "\n"
}

# Grab contentType
# <item contentType="tv_episode" contentId="p079sxm9">
/<item contentType="/ {
    split ($0,fld,"\"")
    contentType = fld[2]
}

# Output wholeItem <item .. item> to a file based on contentType
/<\/item>/ {

    if (contentType == "movie") {
        countMovies += 1
        print wholeItem >> TV_MOVIE_ITEMS
    }

    if (contentType == "tv_show") {
        countShows += 1
        print wholeItem >> TV_SHOW_ITEMS
    }

    if (contentType == "tv_season") {
        countSeasons += 1
        print wholeItem >> TV_SEASON_ITEMS
    }

    if (contentType == "tv_episode") {
        countEpisodes += 1
        print wholeItem >> TV_EPISODE_ITEMS
    }

    # Make sure the wholeItem <item .. item> isn't carried over to the next item
    wholeItem = ""
}

END {
    printf ("In sortBBoxItemsFrom-sitemap.awk\n") > "/dev/stderr"

    countMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    countShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    countSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    countEpisodes == 1 ? pluralEpisodes = "episode" : pluralEpisodes = "episodes"
    #
    printf ("    Processed %d %s, %d %s, %d %s, %d %s\n\n", countMovies, pluralMovies, countShows,
            pluralShows, countSeasons, pluralSeasons, countEpisodes, pluralEpisodes) > "/dev/stderr"
}