# Given the output of an episode file for a TV series from the MHz website
# such as the result from: 
#     curl -s https://mhzchoice.vhx.tv/detective-montalbano
# create lists of names, descriptions, genres, countries, languages, etc.
# to be pasted into a spreadsheet
#
# e.g.
# <title>Detective Montalbano - MHz Choice</title>
# <meta name="description" content="New episodes premiering June 27th!
# MYSTERY | ITALY | ITALIAN WITH ENGLISH SUBTITLES | TV-14
# Murder, betrayal, office politics, temptation... it&#x27;s all in a day&#x27;s work for Detective Salvo Montalbano. Filmed in the ancient, sun-washed Sicilian city of Ragusa Ibla, the series is based on the international best-selling mystery novels by Andrea Camilleri and stars Luca Zingaretti">
#
#
# Invoked with file parameters as follows:
# awk -v NAME_FILE=$NAME_FILE -v HEADER_FILE=$HEADER_FILE \
#     -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
#     -f fetchMHz-episodeInfo.awk

BEGIN {
    numPrinted = 0
    FS = "\|"
}

/title>/ {
    sub (/.*<title>/,"")
    sub (/ - MHz Choice<.*/,"")
    gsub (/&#x27;/,"'")
    print >> NAME_FILE
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
