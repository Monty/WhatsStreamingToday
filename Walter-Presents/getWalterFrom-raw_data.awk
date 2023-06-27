# Grab fields from Walter Presents HTML files
# Title  Seasons  Episodes  Duration  Description

# =HYPERLINK("https://acorn.tv/50shadesofgreen";"50 Shades Of Green")	1	=+1  	00h 46m	Britain's favorite gardener, Alan Titchmarsh, celebrates horticulture around the UK as he counts down his 50 favorite things. With appearances from friends and experts who share his passion--including Mary Berry and Griff Rhys Jones--Alan visits the gorgeous greenery at Kew Gardens, Blenheim Palace, Chatsworth House, and even the place where it all began for him: his grandfather's vegetable garden.

# Title  Seasons  Episodes  Duration  Genre  Country  Language  Rating  Description

# Title  Seasons  Episodes  Duration  Genre  Year  Rating  Description  Content_Type  Content_ID  Show_Type  Date_Type  Season_ID  Sn_#  Ep_#

/^https:/ {
    split ($0,fld,"\t")
    showURL = fld[1]
    showTitle = fld[2]
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
}

/ "description":/ {
    split ($0,fld,"\"")
    showDescription = fld[4]
    # print showDescription
    next
}

# Don't include Previews
/Preview: S[0-9]* Ep[0-9]* \| / || /Preview: Ep[0-9]* \| / {
    next
}

# Don't include Clips
/Clip: S[0-9]* Ep[0-9]* \| / || /Clip: Ep[0-9]* \| / {
    next
}

/ S.[0-9]* Ep[0-9]* \| / {
    episodeLinesFound++
    next
}

/ Ep[0-9]* \| / {
    episodeLinesFound++
    next
}

/ [0-9][0-9]\/[0-9][0-9]\/[0-9][0-9][0-9][0-9] \| / {
    episodeLinesFound++
    next
}


/-- start medium-rectangle-half-page --/ {
    printf ("%s\t%s\t%s\t%s\t%s\n", showLink, showSeasons, episodeLinesFound, \
            showDurationText, showDescription)
    # Make sure there is no carryover
    showURL = ""
    showTitle = ""
    showLink = ""
    showSecs = 0
    showMins = 0
    showHrs = 0
    showDuration = ""
    showDescription = ""
    #
    episodeLinesFound = 0
    seasonLinesFound = 0
    descriptionLinesFound  = 0
    durationLinesFound = 0
}
