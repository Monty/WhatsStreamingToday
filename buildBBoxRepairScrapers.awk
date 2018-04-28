# Build scraper JSON files with a smaller list of individual movies and/or shows to re-scrape
# that are derived from error info

# INVOCATION
#    awk -v REPAIR_EPISODES_FILE=$REPAIR_EPISODES_FILE -v REPAIR_SEASONS_FILE=$REPAIR_SEASONS_FILE \
#        -f buildBBoxRepairScrapers.awk $REPAIR_SHOWS

{
    numShows += 1
    showTitle = $1
    printf ("%s    \"https://www.britbox.com/us/show/%s\"", trailingEpisodesComma, showTitle) \
        >> REPAIR_EPISODES_FILE
    trailingEpisodesComma = ",\n"
    printf ("%s    \"https://www.britbox.com/us/show/%s\"", trailingSeasonsComma, showTitle) \
        >> REPAIR_SEASONS_FILE
    trailingSeasonsComma = ",\n"
}

END {
    print "" >> REPAIR_EPISODES_FILE
    print "" >> REPAIR_SEASONS_FILE
}
