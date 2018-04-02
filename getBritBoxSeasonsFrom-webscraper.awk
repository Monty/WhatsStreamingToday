# Print the processed "Season" lines from a WebScraper csv file saved in tsv format

# Field numbers
#    1 web-scraper-order  2 web-scraper-start-url  3 PgmURL            4 PgmURL-href       5 SsnURL
#    6 SsnURL-href        7 EpiURL                 8 EpiURL-href       9 Program_Title    10 Sn_Title 
#   11 Sn_Years           12 Sn_Epis              13 Sn_Description   14 More_Description

BEGIN {
    FS="\t"
    print "Sortkey\tTitle\tYear(s)\tEpisodes\tDescription"
}

# Only print the preceding line if the current line has a different Program_Title
# or the preceding line had a non-blank SsnURL-href 
NR > 1 {
    if (oldProgram_Title != $9 || oldSsnURL_href != "")
        print savedLine
}

# Save fields from the current line so they can be printed after checking the following line
{
    # Raw fields for comparison
    oldSsnURL_href = $6
    oldProgram_Title = $9

    # Fields to print from current line
    sortkey = NR
    $6  == "" ? URL = $4 : URL = $6
    showTitle = $9
    $10 == "" ? seasonTitle = "Season 1" : seasonTitle = $10
    Years = $11
    NumEpisodes = $12
    $14 == "" ? Description = $13 : Description = $14

    sub (/ Episodes?/,"",NumEpisodes)

    savedLine = sprintf \
        ("%s - %s\t=HYPERLINK(\"%s\";\"%s, %s\"\)\t%s\t%s\t%s",\
         showTitle, sortkey, URL, showTitle, seasonTitle, Years, NumEpisodes, Description)

    next
}

END {
    print savedLine
}
