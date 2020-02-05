# Generate series URLs, Titles, Number of Seasons from MHz "Browse" page
#
# INVOCATION: 
#       curl -s https://watch.mhzchoice.com/series https://watch.mhzchoice.com/series?page=2 \
#           | awk -v URL_FILE=$URL_FILE -v TITLE_FILE=$TITLE_FILE \
#           -v NUM_SEASONS_FILE=$NUM_SEASONS_FILE -v ERROR_FILE=$ERROR_FILE \
#           -f getMHzFrom-browsePage.awk
#
# INPUT:
#       <a href="https://watch.mhzchoice.com/a-french-village"><strong title=\
#       "A French Village">A French Village</strong></a>
#   ---
#       <h4 class="transparent"><span class='media-count'>6 seasons</span></h4>
#
# OUTPUT:
#       $URL_FILE, $TITLE_FILE, $NUM_SEASONS_FILE

/https:\/\/watch.mhzchoice.com\/.*strong title/ {
    split ($0,fld,"\"")
    URL = fld[2]
    # Take care of extra fields introduced in February 2020
    titleString = substr ($0, match ($0, /strong title/))
    split (titleString,fld,"\"")
    TITLE = fld[2]
    #
    shortURL = URL
    sub (/.*watch/,"watch",shortURL)
    print URL >> URL_FILE

    # Canonicalize Title
    gsub (/&#x27;/,"'",TITLE)
    gsub (/&quot;/,"\"\"",TITLE)
    gsub (/&amp;/,"\\&",TITLE)
    if (match (TITLE, /^The /)) {
        TITLE = substr(TITLE, 5) ", The"
    }
    print TITLE >> TITLE_FILE
    next
}

/h4 class="transparent.*media-count/ {
    numSeasons = $0
    sub (/.*media-count'>/,"",numSeasons)
    sub (/ season.*$/,"",numSeasons)
    if ((numSeasons + 0) == 0)
        print "==> No seasons: " shortURL "  " TITLE >> ERROR_FILE
    print numSeasons >> NUM_SEASONS_FILE
}

