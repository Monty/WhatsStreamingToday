# Generate series Marquees, Descriptions, Headers from MHz series pages
#       (Headers include Genre, Country, Language, Rating)
# and return the list of Episode URLs for further processing
#
# INVOCATION:
#       curl -s https://watch.mhzchoice.com/a-french-village/ \
#           | awk -v MARQUEE_FILE=$MARQUEE_FILE -v DESCRIPTION_FILE=$DESCRIPTION_FILE \
#           -v HEADER_FILE=$HEADER_FILE -v EPISODE_URL_FILE=$EPISODE_URL_FILE \
#           -v ERROR_FILE=$ERROR_FILE -f getMHzFrom-seriesPages.awk
#
# INPUT:
#       <meta name="apple-itunes-app" content="app-id=1096194231, \
#           app-argument=https://mhzchoice.vhx.tv/agatha-christie-s-criminal-games">
#       <title>A French Village - MHz Choice</title>
#       <meta name="description" content="DRAMA | FRANCE | FRENCH WITH ENGLISH SUBTITLES | TV-MA^M
#       This acclaimed drama is about the German...all in a day&#x27;s work... its inhabitants.">
# ---
#       <select class="js-switch-season btn-dropdown-black margin-right-medium" data-switch-season >
#           <option value="https://watch.mhzchoice.com/a-french-village/season:1" selected>
#             Season 1
#           </option>
#           <option value="https://watch.mhzchoice.com/a-french-village/season:2">
#             Season 2
#           </option>
#       </select>
# ---
#       <a data-load-more="infinite_scroll: false;" \
#       data-load-more-target="js-load-more-items-container" \
#       class="js-load-more-link btn btn-site-secondary btn-nowrap"
#       href="/detective-montalbano?html=1&amp;page=2">
#
# OUTPUT:
#       $MARQUEE_FILE, $DESCRIPTION_FILE, $HEADER_FILE,
#       list of Episode URLs
#       

/meta name="apple-itunes-app" content=/,/>/ {
    seriesURL = $0
    sub (/.*app-argument=/,"",seriesURL)
    sub (/">/,"",seriesURL)
    sub (/mhzchoice.vhx.tv/,"watch.mhzchoice.com",seriesURL)
    shortURL = seriesURL
    sub (/.*watch/,"watch",shortURL)
}

/title>/ {
    seriesTitle = $0
    sub (/.*<title>/,"",seriesTitle)
    sub (/ - MHz Choice<.*/,"",seriesTitle)
    gsub (/&#x27;/,"'",seriesTitle)
    if (match (seriesTitle, /^The /)) {
        seriesTitle = substr(seriesTitle, 5) ", The"
    }
    print seriesTitle >> MARQUEE_FILE
    next
}

/meta name="description" content=/,/>/ {
    # if we're on the first line of this block ...
    if ($0 ~ /name="description" content="/) {
        headerPrinted = "no"
        sub (/.*name="description" content="/,"")
    }
    # If we find a header, clean it up and print it
    if ($0 ~ /\| {1,2}TV/) {
        sub (/WITH ENGLISH SUBTITLES /,"")
        sub (/SCANDINAVIAN CRIME FICTION/,"Sweden")
        sub (/NONFICTION - DOCUMENTARY/,"Documentary")
        gsub (/ \| {1,2}/,"|")
        sub (/\r/,"")
        # Split out header fields
        numFields = split ($0,fld,"\|")
        # lowercase everything but the first character in all fields but the last
        for (i = 1; i < numFields; ++i) {
            fld[i] = substr(fld[i],1,1) tolower(substr(fld[i],2))
            # uppercase the first character of any second word
            if (match (fld[i],/ /) > 0)
                fld[i] = substr(fld[i],1,RSTART) toupper(substr(fld[i],RSTART+1,1)) \
                (substr(fld[i],RSTART+2))
        }
        # print the finalized header
        if (numFields > 3 ) {
            print fld[1] "\t" fld[2] "\t" fld[(numFields-1)] "\t" fld[(numFields)] >> HEADER_FILE
            headerPrinted = "yes"
        }
    } else {
        # We found a description, clean it up and print it
        gsub (/  */," ")
        gsub (/&#x27;/,"'")
        gsub (/&quot;/,"\"")
        gsub (/&amp;/,"\\&")
        gsub (/&lsquo;/,"’")
        gsub (/&rsquo;/,"’")
        gsub (/&ldquo;/,"“")
        gsub (/&rdquo;/,"”")
        gsub (/\r/," ")
        # if it's not the last line of the description, print it without a newline
        if ($0 !~ /"\>/) {
            printf ("%s", $0) >> DESCRIPTION_FILE
        } else {
            # if it's the last line of the description, print it with a newline
            sub (/"\>/,"")
            print $0 >> DESCRIPTION_FILE
            # if we didn't find a header in this block, print a blank one
            if (headerPrinted == "no") {
                print "==> No genre/country line: " shortURL "  " seriesTitle >> ERROR_FILE
                print "\t\t\t" >> HEADER_FILE
            }
        }
    }
}

# Return the list of Episode URLs for further processing
/<select class="js-switch-season/,/<\/select>/ {
    sub (/^ */,"")
    if ($0 ~ /^<option value="/) {
        split ($0,fld,"\"")
        print fld[2] >> EPISODE_URL_FILE
    }
}

# If there is more to load ...
#       href="/detective-montalbano?html=1&amp;page=2">
/class="js-load-more-link/ {
    if (getline <= 0) {
        print "==> Missing page=2 link: " shortURL "  " seriesTitle >> ERROR_FILE
    }
    sub (/.*href="/,"https://watch.mhzchoice.com")
    sub (/">.*/,"")
    print $0 >> EPISODE_URL_FILE
}
