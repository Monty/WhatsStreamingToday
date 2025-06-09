# Produce a list of BritBox URLs, including shows/seasons/episodes/movies from
# the en-us lines in the SITEMAP_URL https://www.britbox.com/dynamic-sitemap.xml

#  <xhtml:link rel="alternate" hreflang="en-us" href="https://www.britbox.com/us/show/Father_Brown_b03pmw4m" />
#  <xhtml:link rel="alternate" hreflang="en-us" href="https://www.britbox.com/us/season/Father_Brown_S11_m001ttms" />
#  <xhtml:link rel="alternate" hreflang="en-us" href="https://www.britbox.com/us/episode/Father_Brown_S11_m001ttmx" />
#  <xhtml:link rel="alternate" hreflang="en-us" href="https://www.britbox.com/us/movie/Lewis_Behind_the_Scenes_p0g6vg93" />
/en-us/ {
    split($0, fld, "\"")
    url = fld[6]
    sub(/britbox.com\/ca\//, "britbox.com/us/", url)
    print url
}
