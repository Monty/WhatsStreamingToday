# Helper for converting links copied and pasted from a webpage
#
# Since there is no way to paste an embedded hyperlink into a text file,
# paste the link and the title on two consecutive lines, e.g.
#
# https://www.netflix.com/title/80988955
# Death in Paradise, S06E01, Erupting in Murder
#
# https://www.netflix.com/title/80174814
# Borderliner: Season 1: "Milla’s Future"
#
# https://www.netflix.com/title/80203122
# Luxury Travel Show: Season 1: "Chiang Mai & Eze"
#
# Paste them in the same order they are in the Netflix "viewing activity" page

/^https:/ {
    link = $0
    if ((getline title) > 0) {
        gsub (/"/,"\"\"",title)
        printf ("=HYPERLINK(\"%s\";\"%s\")\n",link,title)
    }
}
