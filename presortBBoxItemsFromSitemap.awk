# Rearrange a raw BritBox Catalog (apple_catalogue_feed.xml) so items are sorted by contentType

# INVOCATION:
#    awk -v ERRORS=$ERRORS -v TV_MOVIE_ITEMS=$TV_MOVIE_ITEMS -v TV_SHOW_ITEMS=$TV_SHOW_ITEMS \
#        -v TV_SEASON_ITEMS=$TV_SEASON_ITEMS -v TV_EPISODE_ITEMS=$TV_EPISODE_ITEMS \
#        -v IDS_SEASONS=$IDS_SEASONS -v IDS_EPISODES=$IDS_EPISODES \
#        -f presortBBoxItemsFromSitemap.awk $SITEMAP

# Add inclusive content of <item .. item> to a string
/<item contentType="/, /<\/item>/ { wholeItem = wholeItem $0 "\n" }

# Grab contentType
# <item contentType="tv_episode" contentId="p079sxm9">
/<item contentType="/ {
    split($0, fld, "\"")
    contentType = fld[2]
    contentId = fld[4]
}

# Grab showContentId
# <showContentId>b008yjd9</showContentId>
/<showContentId>/ {
    split($0, fld, "[<>]")
    # showContentId is the parent tv_show's contentId for tv_episodes and tv_seasons
    showContentId = fld[3]
}

# Output wholeItem <item .. item> to a file based on contentType
/<\/item>/ {
    if (contentType == "movie") {
        totalMovies += 1
        print wholeItem >> TV_MOVIE_ITEMS
    }

    if (contentType == "tv_show") {
        totalShows += 1
        print wholeItem >> TV_SHOW_ITEMS
    }

    if (contentType == "tv_season") {
        totalSeasons += 1
        print wholeItem >> TV_SEASON_ITEMS
    }

    if (contentType == "tv_episode") {
        totalEpisodes += 1
        print wholeItem >> TV_EPISODE_ITEMS
    }

    # Make sure the wholeItem <item .. item> isn't carried over to the next item
    wholeItem = ""
    showContentId = ""
}

END {
    printf("In presortBBoxItemsFromSitemap.awk\n") > "/dev/stderr"

    totalMovies == 1 ? pluralMovies = "movie" : pluralMovies = "movies"
    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    #
    printf(\
        "    Processed %d %s, %d %s, %d %s, %d %s\n\n",
        totalMovies,
        pluralMovies,
        totalShows,
        pluralShows,
        totalSeasons,
        pluralSeasons,
        totalEpisodes,
        pluralEpisodes\
    ) > "/dev/stderr"
}
