# Given the output of curl -s https://acorn.tv/browse
# create lists of titles and their urls to be pasted into a spreadsheet
#
# Invoked with file parameters as follows:
# awk -v CAPTION_FILE=$CAPTION_FILE -v URL_FILE=$URL_FILE -f fetchAcorn-series.awk

/itemprop="name"/ {
    sub (/.*title">/,"")
    sub (/<\/p>$/,"")
    print >> CAPTION_FILE
}

/itemprop="url"/ {
    sub (/.*href="/,"")
    sub (/\/">$/,"")
    print $0 "/" >> URL_FILE
}

