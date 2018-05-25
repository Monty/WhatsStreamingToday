#!/usr/bin/env python3
import sys
import imdb

if len(sys.argv) != 2:
    print('[ERROR] Only one argument is allower:')
    print('  %s "movie title"' % sys.argv[0])
    sys.exit(2)

title = sys.argv[1]

i = imdb.IMDb()

out_encoding = sys.stdout.encoding or sys.getdefaultencoding()

try:
    # Do the search, and get the results (a list of Movie objects).
    results = i.search_movie(title)
except imdb.IMDbError as e:
    print("[ERROR] No search result. Not connected to Internet?")
    print(e)
    sys.exit(3)

# Print the results.
print('    %s result%s for "%s":' % (len(results),
                                     ('', 's')[len(results) != 1],
                                     title))
print('movieID\t: imdbID : title')

# Print the long imdb title for every movie.
for movie in results:
    outp = '%s\t: %s : %s' % (movie.movieID, i.get_imdbID(movie),
                               movie['long imdb title'])
    print(outp)
