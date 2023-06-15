/data-show-slug=/ { 
    split ($0,fld,"\"")
    showTitle = fld[6]
    showURL = "https://www.pbs.org/show/" fld[8]
    showLink = "=HYPERLINK(\"" showURL "\";\"" showTitle "\")"
    episodeLink = "=HYPERLINK(\"" showURL "/episodes/\";\"" showTitle "\")"
    print showLink "\t" episodeLink
}
