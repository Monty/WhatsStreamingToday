# Total the duration of episodes in every series
# Update the number of episodes and the total show duration for any that are missing
# NOTE: Depends on file being sorted in reverse order

# INVOCATION:
#        grep -hv ^Sortkey $PROGRAMS_SPREADSHEET_FILE $EPISODES_SPREADSHEET_FILE | sort -f |
#        tail -r | awk -v ERROR_FILE=$ERROR_FILE -f calculateBritBoxDurations.awk |
#        tail -r >>$LONG_SPREADSHEET_FILE

# Field numbers
#    1 Sortkey    2 Title    3 Seasons    4 Episodes    5 Duration    6 Year(s)    7 Rating

BEGIN {
    FS = "\t"
    OFS = "\t"
}

# No processing on header and other lines unrelated to shows
$1 == "" || $1 == "Sortkey" {
    print
    next
}

# Accumulate total time on any line that has a valid duration
$5 != "" {
    if (split ($5, tm, ":") != 3) {
        print "==> Bad duration " $5 " in " $0 >> ERROR_FILE
    } else {
        totalTime[3] += tm[3]
        totalTime[2] += tm[2] + int(totalTime[3] / 60)  
        totalTime[1] += tm[1] + int(totalTime[2] / 60)
        totalTime[3] %= 60; totalTime[2] %= 60
    }
}

# (2) indicates an episode, which should always have a valid duration
# Accumulate series time and episode count on any line that has a valid duration
$1 ~ / \(2\) / {
    if (split ($5, tm, ":") != 3) {
        print "==> Bad duration " $5 " in " $0 >> ERROR_FILE
    } else {
        secs += tm[3]
        mins += tm[2] + int(secs / 60)
        hrs += tm[1] + int(mins / 60)
        secs %= 60; mins %= 60
        episodes += 1
        print
    }
}

# (1) indicates a show, which may or may not have a duration
# If it has no duration, update it from the running total
$1 ~ / \(1\) / {
    if ($5 == "") {
        $4 = episodes
        $5 = sprintf ("%02d:%02d:%02d", hrs, mins, secs)
        secs = 0; mins = 0; hrs = 0;
        episodes = 0
    }
    print
}


END {
    printf ("%02d:%02d:%02d\n", totalTime[1], totalTime[2], totalTime[3])
}
