# Generate series Marquees, Descriptions, Headers from MHz series pages
#       (Headers include Genre, Country, Language, Rating)
# and return the list of Episode URLs for further processing
#
# INVOCATION:
#       curl -s https://mhzchoice.vhx.tv/a-french-village/ \
#           | awk -v MARQUEE_FILE=$MARQUEE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
#           -v HEADER_FILE=$HEADER_FILE -f getMHzFrom-seriesPages.awk
#
# INPUT:
#       <title>A French Village - MHz Choice</title>
#       <meta name="description" content="DRAMA | FRANCE | FRENCH WITH ENGLISH SUBTITLES | TV-MA^M
#       This acclaimed drama is about the German...all in a day&#x27;s worki... its inhabitants.">
#
# OUTPUT:
#       $MARQUEE_FILE, $DESCRIPTION_FILE, $HEADER_FILE,
#       list of Episode URLs
#       

BEGIN {
    numPrinted = 0
    FS = "\|"
}

/title>/ {
    sub (/.*<title>/,"")
    sub (/ - MHz Choice<.*/,"")
    gsub (/&#x27;/,"'")
    if (match ($0, /^The /)) {
        $0 = substr($0, 5) ", The"
    }
    print >> MARQUEE_FILE
}

/meta name="description" content=/,/>/ {
    sub (/.*name="description" content="/,"")
    if ($0 ~ /\| TV/) {
        # Extract the header
        sub (/WITH ENGLISH SUBTITLES /,"")
        sub (/SCANDINAVIAN CRIME FICTION/,"Sweden")
        sub (/NONFICTION - DOCUMENTARY/,"Documentary")
        gsub (/ \| /,"|")
        sub (/\r/,"")
        # ensure lowercase for everything but the first character
        # in all fields but the last
        for (i = 1; i < NF; ++i) {
            $i = substr($i,1,1) tolower(substr($i,2))
            # uppercase for second of two word fields
            if (match($i,/ /) > 0)
                $i = substr($i,1,RSTART) toupper(substr($i,RSTART+1,1)) \
                   (substr($i,RSTART+2))
        }
        # print the finalized header
        print $1 "\t" $2 "\t" $(NF-1) "\t" $(NF) >> HEADER_FILE
        numPrinted += 1
    } else {
        # Extract the description
        gsub (/"\>/,"")
        gsub (/  */," ")
        gsub (/&#x27;/,"'")
        gsub (/\r/," ")
        # print the finalized description
        printf ("%s", $0) >> DESCRIPTION_FILE
    }
}

END {
    if (numPrinted == 0)
        printf ("\t\t\t\n") >> HEADER_FILE
    print "" >> DESCRIPTION_FILE
}
