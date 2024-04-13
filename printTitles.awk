# Format and print episode titles from a csv file with hyperlinks in field 1
#
# =HYPERLINK("https://watch.mhzchoice.com/beck";"Beck")

# INVOCATION:
# awk -f printTitles.awk MHz_TV_ShowsEpisodes-240409.csv
BEGIN { FS = "\t" }

# No processing on header and other lines unrelated to shows
/=HYPERLINK/ {
    split($1, str, "\"")
    title = str[4]
    print title
}
