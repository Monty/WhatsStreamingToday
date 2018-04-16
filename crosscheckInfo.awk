# Crosscheck the number of episodes of each show found by counting them (grep -c)
# in EPISODES_SORTED_FILE versus the number added up from SEASONS_SORTED_FILE
# Both numbers are found by processing a checkEpisodeInfo file
#
# For now these seem more likely a problem in scraping SEASONS_SORTED_FILE than EPISODES_SORTED_FILE
# so it could be these are false positives in generating spreadsheets. The case is stronger for
# problems listed in checkBBox_anomalies files.

# INVOCATION:
#    awk -f crosscheckInfo.awk checkEpisodeInfo-180415.185805.txt

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
    for ( i = 1; i <= numShows; i++ ) {
        if (shouldHave[i] != doesHave[i]) {
            print "==> show  "showTitle[i] " has " doesHave[i] " instead of " \
                shouldHave[i] " episodes."
        }
    }
}
