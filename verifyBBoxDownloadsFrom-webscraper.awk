# Verify that every show in BBoxPrograms is also in BBoxEpisodes

# INVOCATION:
#   awk -v EPISODES_SORTED_FILE=$EPISODES_SORTED_FILE -v SEASONS_SORTED_FILE=$SEASONS_SORTED_FILE \
#       -v TEMP_FILE=$TEMP_FILE -f verifyBBoxDownloadsFrom-webscraper.awk $PROGRAMS_SORTED_FILE \
#       >>$EPISODE_INFO_FILE

# Field numbers
#    1 web-scraper-start-url    2 URL    3 Program_Title    4 Sn_Years    5 Seasons    9  Description

BEGIN {
    FS="\t"
}

/\/us\// {
    programURL = $1
    nflds = split (programURL,fld,"/") 
    showType = fld[3]
    showType == "show" ? spacer = "  " : spacer = " "
    # Must have single quotes to handle special charaters in targets
    target = sprintf ("'%s'",fld[nflds])
    unquotedTarget = substr(target,2,length(target)-2)
    #
    cmd = "grep -c " target " " EPISODES_SORTED_FILE
    if ((cmd | getline NumEpisodes) > 0) {
        NumEpisodes == 1 ? epiStr = " episode" : epiStr = " episodes"
        print "==> " showType spacer target " has " NumEpisodes epiStr
    }
    close (cmd)
    if (NumEpisodes == 0) {
        badEpisodes += 1
        print "    " unquotedTarget >> TEMP_FILE
    }
    #
    cmd = "grep " target " " SEASONS_SORTED_FILE
    while ((cmd | getline seasonLine) > 0) {
        split (seasonLine, fields, "\t")
        seasonField = fields[7]
        episodeField = fields[9]
        if (seasonField == "") {
            print "==> " target " missing Seasons field in " SEASONS_SORTED_FILE \
                > "/dev/stderr"
            print "    " unquotedTarget " missing Seasons field in " SEASONS_SORTED_FILE \
                >> TEMP_FILE
            continue
        }
        print "          " target " " seasonField " has " episodeField

    }
    close (cmd)
}

END {
    print "==> " badEpisodes " Program URLs not found in " EPISODES_SORTED_FILE  > "/dev/stderr"
}
