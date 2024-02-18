# Helper for converting Netflix "viewing activity" into hyperlinks
#

# <a href="/title/80988960" data-reactid="68">Death in Paradise: Season 6: &quot;Man Overboard, Part 2&quot;
# <a href="/title/80170369" data-reactid="124">Ugly Delicious: Season 1: &quot;Pizza&quot;
# <a href="/title/80190361" data-reactid="100">Hinterland: Season 3: &quot;Episode 2&quot;

# INVOCATION:
#    Browse to https://www.netflix.com/viewingactivity
#    Save as 'Page Source'
#    awk -f generateLinksFrom-NetflixActivityPage.awk ~/Downloads/Netflix.html

BEGIN {
    RS="\<"
    # print 10 records unless overridden with "-v maxRecordsToPrint=<n>"
    if (maxRecordsToPrint == "") maxRecordsToPrint = 10
}

/div class="col date nowrap"/ {
    split($0,fld,">")
    date = fld[2]
}

/a href="\/title\// {
    split($0,fld,">")
    title = fld[2]
    match(title, ": Season [[:digit:]]+:")
    if (RLENGTH != -1) {
        title_start = substr(title, 1, RSTART-1)
        season = sprintf(", S%02dE00,", substr(title, RSTART+8, RLENGTH-9))
        title_end = substr(title, RSTART+RLENGTH)
        title = title_start season title_end
    }
    split($0,fld,"\"")
    URL = fld[2]
    gsub(/&quot;/,"",title)
    printf("=HYPERLINK(\"https://www.netflix.com%s\";\"%s\")\t%s\tNetflix Streaming\n",\
            URL,title,date)
    recordsPrinted += 1
    if (recordsPrinted >= maxRecordsToPrint)
        exit
}
