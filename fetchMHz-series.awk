# Given the output of:
#    curl -s https://mhzchoice.vhx.tv/series https://mhzchoice.vhx.tv/series?page=2
# create lists of titles, urls and seasons to be pasted into a spreadsheet
#
# e.g.
# <a href="https://mhzchoice.vhx.tv/a-french-village"><strong title="A French Village">A French Village</strong></a>
# <h4 class="transparent"><span class='media-count'>6 seasons</span></h4>
#
#
# Invoked with file parameters as follows:
# awk -v URL_FILE=$URL_FILE -v TITLE_FILE=$TITLE_FILE \
#     -v SEASONS_FILE=$SEASONS_FILE -f fetchMHz-series.awk

/https:\/\/mhzchoice.vhx.tv\/.*strong title/ {
    sub (/.*href="/,"")
    endTitle = match($0,/"/ ) -1
    print substr($0,1,endTitle) "/" >> URL_FILE

    sub (/.*strong title="/,"")
    sub (/".*$/,"")
    gsub (/&#x27;/,"'")
    print >> TITLE_FILE
}

/h4 class="transparent.*media-count/ {
    sub (/.*media-count'>/,"")
    sub (/ season.*$/,"")
    print $0 >> SEASONS_FILE
}

