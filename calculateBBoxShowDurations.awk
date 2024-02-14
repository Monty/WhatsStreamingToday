# Generate SHORT_SPREADSHEET by processing LONG_SPREADSHEET to calculate and include durations
#
# Generate a grand total duration by adding up the duration of episodes and movies
# Generate totals for each show by adding up the duration of its episodes
# Update the number of episodes and the show's duration for any that are missing
# NOTE: Depends on file being sorted in reverse order

# INVOCATION:
#    tail -r $LONG_SPREADSHEET | awk -v ERRORS=$ERRORS -v DURATION="$DURATION" \
#        -f calculateBBoxShowDurations.awk | tail -r >>$SHORT_SPREADSHEET

# Field numbers returned by getBBox*.awk scripts
#     1 Title       2 Seasons     3 Episodes        4 Duration       5 Genre
#     6 Year        7 Rating      8 Description     9 Content_Type  10 Content_ID
#    11 Item_Type  12 Date_Type  13 Original_Date  14 Show_ID       15 Season_ID
#    16 Sn_#       17 Ep_#       16 1st_#          17 Last_#

BEGIN {
    FS = "\t"
    OFS = "\t"
}

# No processing on header and other lines unrelated to shows
!/^=HYPERLINK/ {
    print
    next
}

# Accumulate total time on any line that has a valid duration
# this includes all movies and all episodes
$4 != "" {
    # Check all durations for strict HH:MM:SS format
    if ($4 !~ /^0:[0-9]+$/) {
        print "==> Bad duration " $4 " in " $0 >> ERRORS
        print
        next
    } else {
        split ($4, tm, ":")
        totalTime[2] += tm[2]
        totalTime[1] += tm[1] + int(totalTime[2] / 60)
        totalTime[2] %= 60
    }
}

# "tv_episode" indicates an episode, which should always have a valid duration
# Accumulate series time and episode count on any line that has a valid duration
# But don't print episodes in short spreadsheet
$9 == "tv_episode" {
        mins += tm[2]
        hrs += tm[1] + int(mins / 60)
        mins %= 60
        episodes += 1
        next
}

# "tv_show" indicates a show, which may or may not have a duration
# If it has no duration, update it from the running total
$9 == "tv_show" {
    if ($4 == "") {
        $3 = episodes
        $4 = sprintf ("%02dh %02dm", hrs, mins)
        mins = 0; hrs = 0;
        episodes = 0
        print
        next
    }
}

$9 == "tv_movie" {
    mins = tm[2]
    hrs = tm[1] + int(mins / 60)
    mins %= 60
    $4 = sprintf ("%02dh %02dm", hrs, mins)
    mins = 0; hrs = 0;
    print
}

END {
    printf ("%02dh %02dm\n", totalTime[1], totalTime[2]) >> DURATION
}
