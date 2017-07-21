# Total the duration of all episodes in every series
#
# INVOCATION:
#       awk -v DURATION_FILE=$DURATION_FILE -f calculateMHzDurations.awk $EPISODE_INFO_FILE
#
# INPUT:
#  1 \t =HYPERLINK("https://mhzchoice.vhx.tv/detective-montalbano/season:1/videos/the-snack-thief",\
#  \t \t "Detective Montalbano, S01E01, Montalbano: The Snack Thief") \t 1:45:05 An elderly \
#  import-export merchant is found murdered and a young woman who may have been mixed up with \
#  him disappears the same day. Directed by Alberto Sironi, 1999.
#
# OUTPUT:
#       $DURATION_FILE with one total duration of a series per line

# Extract the duration
BEGIN {
    FS = "\t"
}

{
    series = $1
    if (split ($5, tm, ":") == 3) {
        secs[series] += tm[3]
        mins[series] += tm[2] + int(secs[series] / 60)
        hrs[series] += tm[1] + int(mins[series] / 60)
        secs[series] %= 60; mins[series] %= 60
    } else {
        # This is not strictly necessary. We should never get 2 part durations anymore
        secs[series] += tm[2]
        mins[series] += tm[1] + int(secs[series] / 60)
        hrs[series] += int(mins[series] / 60)
        secs[series] %= 60; mins[series] %= 60
    }
}

END {
    for ( i = 1; i <= series; i++ ) {
        totalTime[3] += secs[i]
        totalTime[2] += mins[i] + int(totalTime[3] / 60)
        totalTime[1] += hrs[i] + int(totalTime[2] / 60)
        totalTime[3] %= 60; totalTime[2] %= 60
        # Print the total duration of each series
        printf ("%02d:%02d:%02d\n", hrs[i], mins[i], secs[i]) >> DURATION_FILE
    }
    # Return the total duration of all series
    printf ("%02d:%02d:%02d\n", totalTime[1], totalTime[2], totalTime[3])
}

