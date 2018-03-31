# Print only the valid "Seasons" lines from a WebScraper csv file saved in tsv format

# Field numbers
#    1 web-scraper-order  2 web-scraper-start-url  3 PgmURL            4 PgmURL-href       5 SsnURL
#    6 SsnURL-href        7 EpiURL                 8 EpiURL-href       9 Program_Title    10 Sn_Title 
#   11 Sn_Years           12 Sn_Epis              13 Sn_Description   14 More_Description

BEGIN {
    FS="\t"
}

# Only print the preceding line if the current line has a new Program_Title
# or the preceding line had a non-blank SsnURL-href 
NR > 1 {
    SsnURL_href =$6
    Program_Title = $9
    if (Program_Title != oldProgram_Title || oldSsnURL_href != "")
        print oldline
}

# Always save the current line so it can be printed after chaecking the following line
{
    oldline = $0
    oldSsnURL_href = $6
    oldProgram_Title = $9
    next
}

END {
    print NR-1 " - "oldline
}
