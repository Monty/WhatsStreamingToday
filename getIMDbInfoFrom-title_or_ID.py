#!/usr/bin/env python3
import sys
import imdb

out_encoding = sys.stdout.encoding or sys.getdefaultencoding()
i = imdb.IMDb()

if len(sys.argv) != 2:
    print('[ERROR] Only one argument is allowed:')
    print('  %s "movie title or movie_id"' % sys.argv[0])
    sys.exit(2)

param1 = sys.argv[1]

try:
    # Do the search, and get the result (a list of Movie objects or a movie_id).
    # Does it look like a 7 digit IMDb movie_id?
    if param1.isdigit() and len(param1) == 7:
        result = i.get_movie(param1)
    else:
        result = i.search_movie(param1)
except imdb.IMDbError as e:
    print("[ERROR] No result returned. Not connected to Internet?")
    print(e)
    sys.exit(3)

if not result:
    print('[ERROR] No matches for "%s".' % param1)
    sys.exit(0)

# We have a Movie instance.
if param1.isdigit() and len(param1) == 7:
    movie = result
else:
    movie = result[0]

imdbURL = i.get_imdbURL(movie)

# So far the Movie object only contains basic information like the
# title and the year; retrieve main information:
i.update(movie)

cast = movie.get('cast')
if cast:
    for name in cast:
        print('%s\t"%s"\t%s\tActor' % (imdbURL, movie['title'], name['name']))

director = movie.get('director')
if director:
    for name in director:
        print('%s\t"%s"\t%s\tDirector' % (imdbURL, movie['title'], name['name']))

writer = movie.get('writer')
if writer:
    for name in writer:
        print('%s\t"%s"\t%s\tWriter' % (imdbURL, movie['title'], name['name']))
