# WebScraper has problems getting incomplete data.
#
# Crosscheck the info in EPISODES with the info in SEASONS. Count up episodes
# and compare with the number of episodes listed in the seasons file.

# For now these seem more likely a problem in scraping SEASONS than EPISODES
# so it could be these are false positives in generating spreadsheets. 
# Problems listed in BBox_anomalies files are more likely to be real.

# INVOCATION
#    awk -f verifyBBoxInfoFrom-webscraper.awk BBox_episodeInfo-180421.123042.txt

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
