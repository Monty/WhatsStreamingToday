# Generate SHORT_SPREADSHEET by processing LONG_SPREADSHEET to calculate and include durations
#
# Generate a grand total duration by adding up the duration of episodes and movies
# Generate totals for each show by adding up the duration of its episodes
# Update the number of episodes and the show's duration for any that are missing
# NOTE: Depends on file being sorted in reverse order

# INVOCATION:
#    tail -r $LONG_SPREADSHEET | awk -v ERRORS=$ERRORS -v DURATION="$DURATION" \
#        -f calculateBBoxShowDurations.awk | tail -r >>$SHORT_SPREADSHEET

# Field numbers returned by getBBoxCatalogFrom-sitemap.awk
#     1 Sortkey       2 Title           3 Seasons          4 Episodes      5 Duration     6 Year
#     7 Rating        8 Description     9 Content_Type    10 Content_ID   11 Entity_ID   12 Genre
#    13 Show_Type    14 Date_Type      15 Original_Date   16 Show_ID      17 Season_ID   18 Sn_#
#    19 Ep_#         20 1st_#          21 Last_#

BEGIN {
    FS = "\t"
    OFS = "\t"
}

# No processing on header and other lines unrelated to shows
$1 == "" || $1 == "Sortkey" {
    print
    next
}

# Don't add seasons to short spreadsheet
$9 == "tv_season" {
    next
}

# Accumulate total time on any line that has a valid duration
# this incudes all movies and all episodes
$5 != "" {
    # Check all durations for strict HH:MM:SS format
    if ($5 !~ /^[[:digit:]]{2}:[[:digit:]]{2}:[[:digit:]]{2}$/) {
        print "==> Bad duration " $5 " in " $0 >> ERRORS
        print
        next
    } else {
        split ($5, tm, ":")
        totalTime[3] += tm[3]
        totalTime[2] += tm[2] + int(totalTime[3] / 60)  
        totalTime[1] += tm[1] + int(totalTime[2] / 60)
        totalTime[3] %= 60; totalTime[2] %= 60
    }
}

# "tv_episode" indicates an episode, which should always have a valid duration
# Accumulate series time and episode count on any line that has a valid duration
# But don't print episodes in short spreadsheet
$9 == "tv_episode" {
        secs += tm[3]
        mins += tm[2] + int(secs / 60)
        hrs += tm[1] + int(mins / 60)
        secs %= 60; mins %= 60
        episodes += 1
        next
}

# "tv_show" indicates a show, which may or may not have a duration
# If it has no duration, update it from the running total
$9 == "tv_show" {
    if ($5 == "") {
        $4 = episodes
        $5 = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
        secs = 0; mins = 0; hrs = 0;
        episodes = 0
        print
        next
    }
}

$9 == "tv_movie" {
    print
}

END {
    printf ("%02d:%02d:%02d\n", totalTime[1], totalTime[2], totalTime[3]) >> DURATION
}
