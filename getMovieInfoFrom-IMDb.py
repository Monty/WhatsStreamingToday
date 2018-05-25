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

if not results:
    print('No matches for "%s", sorry.' % title)
    sys.exit(0)

# Print only the first result.
print('    Best match for "%s"' % title)

# This is a Movie instance.
movie = results[0]

# So far the Movie object only contains basic information like the
# title and the year; retrieve main information:
i.update(movie)

print ('==== "%s" / Rating: %s ====' % (movie['title'], movie.get('rating')))
cast = movie.get('cast')
if cast:
    print ('Cast: ')
    for name in cast:
        print ('      %s (%s)' % (name['name'], name.currentRole))
# print(movie.summary())
