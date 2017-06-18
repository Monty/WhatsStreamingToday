# Given the output of curl -s https://acorn.tv/browse
# create lists of titles and their urls to be pasted into a spreadsheet
#
# Invoked with file parameters as follows:
# awk -v URL_FILE=$URL_FILE -v MARQUEE_FILE=$MARQUEE_FILE -f fetchAcorn-series.awk

/itemprop="name"/ {
    sub (/.*title">/,"")
    sub (/<\/p>$/,"")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    print >> MARQUEE_FILE
}

/itemprop="url"/ {
    sub (/.*href="/,"")
    sub (/\/">$/,"")
    print $0 "/" >> URL_FILE
}

