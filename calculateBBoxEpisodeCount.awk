# Calculate tne number of episodes for shows in LONG_SPREADSHEET
#
# Update the number of episodes for any that are missing
# NOTE: Depends on file being sorted in reverse order

# INVOCATION:
#   mv "$LONG_SPREADSHEET" "$TEMP_SPREADSHEET"
#   tail -r "$TEMP_SPREADSHEET" | awk -v ERRORS="$ERRORS" \
#       -f calculateBBoxEpisodeCount.awk | tail -r >"$LONG_SPREADSHEET"

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

# "tv_episode" indicates an episode, increment the episode count
$9 == "tv_episode" {
    episodes += 1
    print
    next
}

# "tv_show" indicates a show. Update it from the running episode count
$9 == "tv_show" {
    if (episodes == 0) { print "==> No episodes in " $0 >> ERRORS }

    $3 = episodes
    episodes = 0
    print
    next
}

$9 == "tv_movie" {
    print
    next
}
