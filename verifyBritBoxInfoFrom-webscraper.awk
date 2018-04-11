# WebScraper has problems getting incomplete data.
# This crosschecks the info obtained from verifyBritBoxDownloadsFrom-webscraper.awk
# by counting up episodes and comparing with the listed number of episodes

/ movie / {
    title = $3
    numEpisodes = $5
    if (numEpisodes == 0)
        print
}

/ show / {
    numShows += 1
    showTitle[numShows] = $3 
    shouldHave[numShows] = $5
    doesHave[numShows] = 0
    if (numEpisodes == 0)
        print
}

/^         / {
    epis  = NF-1
    if ($epis !~ /^[[:digit:]]*$/)
        print "==> Bad input line " NR "\n" $0
    else
        doesHave[numShows] += $epis
}

END {
    print ""
    for ( i = 1; i <= numShows; i++ ) {
        if (shouldHave[i] != doesHave[i]) {
            print "==> show  "showTitle[i] " has " doesHave[i] " instead of " \
                shouldHave[i] " episodes."
        }
    }
}
