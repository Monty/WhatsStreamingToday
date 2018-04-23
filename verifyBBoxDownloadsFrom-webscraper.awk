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
    numSeasons = $4

    seaStr = ""
    if (numSeasons != "null") {
        sub (/ Seasons?/,"",numSeasons)
        numSeasons == 1 ? seaStr = " in 1 season" : seaStr = " in " numSeasons " seasons"
    }

nflds = split (programURL,fld,"/") 
showType = fld[3]
showType == "show" ? spacer = "  " : spacer = " "
# Must have single quotes to handle special charaters in targets
target = sprintf ("'%s'",fld[nflds])
unquotedTarget = substr(target,2,length(target)-2)
#
cmd = "grep -c " target " " EPISODES_SORTED_FILE
if ((cmd | getline numEpisodes) > 0) {
    numEpisodes == 1 ? epiStr = " episode" : epiStr = " episodes"
    print "==> " showType spacer target " has " numEpisodes epiStr seaStr
}
close (cmd)
if (numEpisodes == 0) {
    badEpisodes += 1
    print "    " unquotedTarget >> TEMP_FILE
}
#
cmd = "grep " target " " SEASONS_SORTED_FILE
while ((cmd | getline seasonLine) > 0) {
    nfields = split (seasonLine, fields, "\t")
    seasonField = fields[nfields-4]
    episodeField = fields[nfields-2]
    if (seasonField == "") {
        print "==> " target " (blank Seasons field in " SEASONS_SORTED_FILE ")" \
            > "/dev/stderr"
        print "    " unquotedTarget " (blank Seasons field in " SEASONS_SORTED_FILE ")" \
            >> TEMP_FILE
        continue
    }
    print "          " target " " seasonField " has " episodeField

}
close (cmd)
}

END {
    if (badEpisodes > 0 ) {
        badEpisodes == 1 ? field = "URL" : field = "URLs"
        printf ("==> %2d extra /program/ %s in %s\n", badEpisodes, field, FILENAME) > "/dev/stderr"
    }
}
