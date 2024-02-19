# Generate SHORT_SPREADSHEET by processing LONG_SPREADSHEET to calculate and include durations
#
# Generate a grand total duration by adding up the duration of episodes
# Generate totals for each show by adding up the duration of its episodes
# Update the number of episodes and the show's duration for any that are missing
# NOTE: Depends on file being sorted in reverse order

# INVOCATION:
#    sort -fu --key=4 --field-separator=\" $UNSORTED | tail -r | awk -v ERRORS=$ERRORS \
#        -v DURATION="$DURATION" -v LONG_SPREADSHEET=$LONG_SPREADSHEET -f calculateMHzShowDurations.awk |
#        tail -r >$SHORT_SPREADSHEET

# Field numbers returned by getMHzCatalogFromSitemap.awk
#    1 Title    2 Seasons    3 Episodes    4 Duration    5 Genre    6 Country    7 Language
#    8  Rating    9 Description
BEGIN {
    FS = "\t"
    OFS = "\t"
}

# No processing on header and other lines unrelated to shows
$1 !~ /=HYPERLINK/ {
    print
    print >> LONG_SPREADSHEET
    next
}

# No processing on seasons lines, but count them
$3 != "" { totalSeasons += 1 }

# Accumulate total time on any line that has a valid duration, it must be an episode
$4 != "" {
    # Are we a "First Look" episode? Print it, but don't count it as a real episode
    if ($1 ~ /, PR \| /) {
        # Don't use its duration
        $4 = ""
        print >> LONG_SPREADSHEET
        # Skip everything else
        next
    }

    # We have a normal episode
    episodesCounted += 1
    # print "==> episodesCounted = " episodesCounted > "/dev/stderr"
    print >> LONG_SPREADSHEET
    # Check all durations for strict HH:MM:SS format
    if ($4 !~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) {
        print "==> Bad duration " $4 " in " $0 >> ERRORS
        next
    }

    # We have a valid duration, add to total
    split($4, tm, ":")
    totalTime[3] += tm[3]
    totalTime[2] += tm[2] + int(totalTime[3] / 60)
    totalTime[1] += tm[1] + int(totalTime[2] / 60)
    totalTime[3] %= 60
    totalTime[2] %= 60
    totalEpisodes += 1
    # Accumulate episode times to use when a show line is found
    secs += tm[3]
    mins += tm[2] + int(secs / 60)
    hrs += tm[1] + int(mins / 60)
    secs %= 60
    mins %= 60
    next
}

# If a line has seasons, it must be a show - Add it to the short spreadsheet
# If it has no episodes or duration, update them from the running total
$2 != "" {
    if ($3 == "") {
        $3 = episodesCounted
        $4 = sprintf("%02dh %02dm", hrs, mins)
        # Print line with episodesCounted and duration to short spreadsheet
        print
        # Don't print show duration to LONG_SPREADSHEET so durations column can be summed
        $4 = ""
        print >> LONG_SPREADSHEET
        totalShows += 1
        # Make sure there is no carryover
        secs = 0
        mins = 0
        hrs = 0
        episodesCounted = 0
        next
    }
}

END {
    printf("%02dh %02dm\n", totalTime[1], totalTime[2]) >> DURATION

    printf("In calculateMHzShowDurations.awk\n") > "/dev/stderr"

    totalShows == 1 ? pluralShows = "show" : pluralShows = "shows"
    totalSeasons == 1 ? pluralSeasons = "season" : pluralSeasons = "seasons"
    totalEpisodes == 1\
        ? pluralEpisodes = "episode"\
        : pluralEpisodes = "episodes"
    #
    printf(\
        "    Processed %d %s, %d %s, %d %s\n",
        totalShows,
        pluralShows,
        totalSeasons,
        pluralSeasons,
        totalEpisodes,
        pluralEpisodes\
    ) > "/dev/stderr"
}
