# Rebuild Acorn-baseline directory from an Acorn_TV spreadsheet

# INVOCATION:
#     awk -v VERBOSE=$VERBOSE \
#         -v DESCRIPTIONS=$BASELINE/descriptions.txt \
#         -v DURATIONS=$BASELINE/durations.txt \
#         -v EPISODE_CURLS=$BASELINE/episodeCurls.txt \
#         -v EPISODE_DESCRIPTION=$BASELINE/episodeDescription.txt \
#         -v EPISODE_INFO=$BASELINE/episodeInfo.txt \
#         -v LINKS=$BASELINE/links.txt \
#         -v MARQUEES=$BASELINE/marquees.txt \
#         -v NUMBER_OF_EPISODES=$BASELINE/numberOfEpisodes.txt \
#         -v NUMBER_OF_SEASONS=$BASELINE/numberOfSeasons.txt \
#         -v TITLES=$BASELINE/titles.txt \
#         -v URLS=$BASELINE/urls.txt \
#         -f rebuildAcornBaseline.awk \
#         Acorn_TV_ShowsEpisodes-$DATE.csv

# ==> Acorn-baseline/spreadsheetEpisodes.txt <==
#  #    Title    Seasons    Episodes    Duration    Description
#  1    =HYPERLINK("https://acorn.tv/192";"19-2")    3    =+10+10+10    22:11:00    "The writing is sublime" (New York Times) in this anything-but-a-procedural cop drama from Canada. Winner of the Canadian Screen Award for Best Drama and recently nominated for an International Emmy, 19-2 is a slow-burn crime drama that "makes the genre seem new again" (Wall Street Journal) and "defies expectations" (The New York Times). Jared Keeso (Elysium) and Adrian Holmes (Arrow) star as reluctant partners patrolling the streets of Montreal. CC Available.
#  1    =HYPERLINK("https://acorn.tv/192/series1/partners";"19-2, S01E01, Partners")            00:44:06    Still riddled with guilt after a shooting, seasoned police officer Nick Barron returns to Station 19 following temporary leave. He is partnered with Ben Chartier, a transfer from a small, rural police force. Their relationship starts off on a bad note after a split-second decision initiates an internal investigation.

/=HYPERLINK/ {
    split ($0,fld,"\t")
    seriesNum = fld[1]
    link = fld[2]
    numberOfSeasons = fld[3]
    numberOfEpisodes = fld[4]
    duration = fld[5]
    description = fld[6]
    split (link,subfld,"\"")
    url = subfld[2]
    title = subfld[4]
    lineNum += 1
    sortKey = sprintf ("%03d.%05d\t", seriesNum, lineNum)
    if (numberOfSeasons != "") {
        print sortKey url >> URLS
        print sortKey title >> TITLES
        print sortKey title >> MARQUEES
        print sortKey link >> LINKS
        print sortKey numberOfSeasons >> NUMBER_OF_SEASONS
        print sortKey numberOfEpisodes >> NUMBER_OF_EPISODES
        print sortKey duration >> DURATIONS
        print sortKey description >> DESCRIPTIONS
    } else {
        print sortKey "url = \"" url "\"" >> EPISODE_CURLS
        print sortKey seriesNum "\t" link "\t\t\t" duration >> EPISODE_INFO
        print sortKey description >> EPISODE_DESCRIPTION
    }
}
