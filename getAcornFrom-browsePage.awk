# Generate series Marquees and URLs from Acorn "Browse" page
#
# INVOCATION:
#       curl -s https://acorn.tv/browse \
#           | awk -v URL_FILE=$URL_FILE -v MARQUEE_FILE=$MARQUEE_FILE \
#           -v ERROR_FILE=$ERROR_FILE -f getAcornFrom-browsePage.awk
#
# INPUT:
#       <p itemprop="name" class="franchise-title">19-2</p>
#   ---
#       <a itemprop="url" href="https://acorn.tv/192/">
#
# OUTPUT:
#       $MARQUEE_FILE, $URL_FILE

# Extract the Marquee
/<p itemprop="name"/ {
    split ($0,fld,"[<>]")
    marquee = fld[3]
    gsub (/&amp;/,"\\&", marquee)
    gsub (/&quot;/,"\"\"",marquee)
    if (match (marquee, /^The /)) {
        marquee = substr(marquee, 5) ", The"
    }
    print marquee >> MARQUEE_FILE
}

# Extract the URL
/itemprop="url"/ {
    split ($0,fld,"\"")
    URL = fld[4]
    sub (/\/$/,"",URL)
    print URL >> URL_FILE
    print "url = \"" URL "\"" >> CURL_CONFIG_FILE
}

