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
#       This acclaimed drama is about the German...all in a day&#x27;s work... its inhabitants.">
#
# OUTPUT:
#       $MARQUEE_FILE, $DESCRIPTION_FILE, $HEADER_FILE,
#       list of Episode URLs
#       

BEGIN {
    printed = "no"
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
        # Split out header fields
        numFields = split($0,fld,"\|")
        # lowercase everything but the first character in all fields but the last
        for (i = 1; i < numFields; ++i) {
            fld[i] = substr(fld[i],1,1) tolower(substr(fld[i],2))
            # uppercase the first character of any second word
            if (match(fld[i],/ /) > 0)
                fld[i] = substr(fld[i],1,RSTART) toupper(substr(fld[i],RSTART+1,1)) \
                   (substr(fld[i],RSTART+2))
        }
        # print the finalized header
        print fld[1] "\t" fld[2] "\t" fld[(numFields-1)] "\t" fld[(numFields)] >> HEADER_FILE
        printed = "yes"
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
    if (printed == "no")
        print "\t\t\t" >> HEADER_FILE
    print "" >> DESCRIPTION_FILE
}
