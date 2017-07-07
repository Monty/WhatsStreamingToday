# Generate series URLs, Titles, Number of Seasons from MHz "Browse" page
#
# INVOCATION: 
#       curl -s https://mhzchoice.vhx.tv/series https://mhzchoice.vhx.tv/series?page=2 \
#           | awk -v URL_FILE=$URL_FILE -v TITLE_FILE=$TITLE_FILE \
#           -v NUM_SEASONS_FILE=$NUM_SEASONS_FILE -f getMHzFrom-browsePage.awk
#
# INPUT:
#       <a href="https://mhzchoice.vhx.tv/a-french-village"><strong title=\
#       "A French Village">A French Village</strong></a>
#   ---
#       <h4 class="transparent"><span class='media-count'>6 seasons</span></h4>
#
# OUTPUT:
#       $URL_FILE, $TITLE_FILE, $NUM_SEASONS_FILE

/https:\/\/mhzchoice.vhx.tv\/.*strong title/ {
    split($0,fld,"\"")
    URL = fld[2]
    TITLE = fld[4]
    print URL "/" >> URL_FILE

    # Canonicalize Title
    gsub (/&#x27;/,"'",TITLE)
    if (match (TITLE, /^The /)) {
        TITLE = substr(TITLE, 5) ", The"
    }
    print TITLE >> TITLE_FILE
}

/h4 class="transparent.*media-count/ {
    sub (/.*media-count'>/,"")
    sub (/ season.*$/,"")
    print $0 >> NUM_SEASONS_FILE
}

