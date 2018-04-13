BEGIN {
    FS = "\""
}

/\/us\/movie\// {
    numMovies += 1
    shortURL = $6
    printf ("%s    \"https://www.britbox.com%s\"", trailingComma, shortURL) >> EPISODES_JSON_FILE
    trailingComma = ",\n"
}

/\/us\/show\// {
    numShows += 1
    shortURL = $6
    printf ("%s    \"https://www.britbox.com%s\"", trailingComma, shortURL) >> EPISODES_JSON_FILE
    printf ("%s    \"https://www.britbox.com%s\"", trailingComma, shortURL) >> SEASONS_JSON_FILE
    trailingComma = ",\n"
}

END {
    print "" >> EPISODES_JSON_FILE
    print "" >> SEASONS_JSON_FILE
    print "==> Found " numMovies " movies"
    print "==> Found " numShows " shows"
}
