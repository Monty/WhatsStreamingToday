# Verify that every show in BritBoxPrograms is also in BritBoxEpisodes

# INVOCATION:
#   awk -v EPISODES_FILE=$EPISODES_FILE -v SEASONS_FILE=$SEASONS_FILE -v ERROR_FILE=$ERROR_FILE \
#       -f verifyBritBoxDownloadsFrom-webscraper.awk BritBoxPrograms.csv

# Field numbers
#    1 web-scraper-order  2 web-scraper-start-url  3 URL        4 Program_Title   5 Sn_Years
#    6 Seasons            7  Mv_Year               8  Duration  9  Rating        10  Description

# Example input from scraping with getBritBoxProgramsFrom-webscraper.json
# "1523123734-54","https://www.britbox.com/us/programmes","/us/movie/Christmas_Lights_15512",\
#      "Christmas Lights","null","null","2004","90 min","TV-PG",<description>
# "1523201776-3607","https://www.britbox.com/us/programmes","/us/show/Are_You_Being_Served_6429",\
#      "Are You Being Served?","1972–1985","10 Seasons","null","null","null", <description>

BEGIN {
    FS="\""
}

/^"/ {
    programURL = $6
    nflds = split (programURL,fld,"/") 
    showType = fld[3]
    showType == "show" ? spacer = "  " : spacer = " "
    target = sprintf ("'%s' ",fld[nflds])
    #
    cmd = "grep -c " target " " EPISODES_FILE
    if ((cmd | getline NumEpisodes) > 0) {
        NumEpisodes == 1 ? epiStr = " episode" : epiStr = " episodes"
        print "==> " showType spacer target "has " NumEpisodes epiStr
    }
    close (cmd)
    #
    cmd = "grep " target " " SEASONS_FILE
    while ((cmd | getline seasonLine) > 0) {
        split (seasonLine, fields, "\"")
        if (fields[20] == "")
            continue
        print "          " target fields[20] " has " fields[24]
    }
    close (cmd)
}