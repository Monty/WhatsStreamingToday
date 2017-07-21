# Generate series Marquees and URLs from Acorn "Browse" page
#
# INVOCATION:
#       curl -s https://acorn.tv/browse \
#           | awk -v URL_FILE=$URL_FILE -v MARQUEE_FILE=$MARQUEE_FILE \
#           -f getAcornFrom-browsePage.awk
#
# INPUT:
#       <p itemprop="name" class="franchise-title">19-2</p>
#   ---
#       <a itemprop="url" href="https://acorn.tv/192/">
#
# OUTPUT:
#       $MARQUEE_FILE, $URL_FILE

# Extract the Marquee
/itemprop="name"/ {
    sub (/.*title">/,"")
    sub (/<\/p>$/,"")
    gsub (/&amp;/,"\\&")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    print >> MARQUEE_FILE
}

# Extract the URL
/itemprop="url"/ {
    split ($0,fld,"\"")
    print fld[4] >> URL_FILE
}

