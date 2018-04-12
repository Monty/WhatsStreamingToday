BEGIN {
    FS = "\""
}

/\/us\/movie\// {
    numMovies += 1
    shortURL = $6
    printf ("%s    \"https://www.britbox.com%s\"", trailingMovieComma, shortURL) >> MOVIES_JSON_FILE
    trailingMovieComma = ",\n"
}

/\/us\/show\// {
    numShows += 1
    shortURL = $6
    printf ("%s    \"https://www.britbox.com%s\"", trailingShowComma, shortURL) >> EPISODES_JSON_FILE
    trailingShowComma = ",\n"
}

END {
    print "" >> MOVIES_JSON_FILE
    print "" >> EPISODES_JSON_FILE
    print "==> Found " numMovies " movies"
    print "==> Found " numShows " shows"
}
