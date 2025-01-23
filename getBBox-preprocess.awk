# Extract meaningful fields from raw BBox HTML files

# <hero-actions showid="16103" contentid="16103" path="/movie/300_Years_of_French_and_Saunders_p05wv7gy" :item="{"type":"movie","advisoryText":"","copyright":"","distributor":"BBC","description":"Comedy dream team Dawn French and Jennifer Saunders reunite for thefirst time in ten years for a thirtieth-anniversary show bursting mirth,mayhem, And wigs. Lots and lots of wigs.","customMetadata":[],"genrePaths":["/movies/genres/Comedy"],"credits":[{"role":"actor","name":"Dawn French","path":"/name/Dawn_French","character":"Variouscharacters"},{"role":"actor","name":"Jennifer Saunders","path":"/name/Jennifer_Saunders","character":"Various characters"}

# Fields in hero-actions line
# ,"title":"
# {"role":
# ,"name":
# ,"character":

# ,"description":"
# ,"path":"
# ,"numberOfSeasons":
# ,"sameAs":

# ,"title":"300 Years of French and Saunders","
/,"title":"/ {
    if (match($0, /,"title":"[^"]+","/)) {
        title = substr($0, RSTART + 1, RLENGTH - 3)
        # print "title = " title
        split(title, fld, "\"")
        print "title: " fld[4]
    }
}

# ,"description":"Comedy ... lots of wigs.","
/,"description":"/ {
    if (match($0, /,"description":"([^"]|\\")*","/)) {
        description = substr($0, RSTART + 16, RLENGTH - 19)
        print "description: " description
    }
}

# {"role":"actor","name":"Victoria Graham","path":"/name/Victoria_Graham","character":"Newsreader"}
/\{"role":"/ {
    credits = $0

    while (match(credits, /\{"role":[^}]*\}/)) {
        castMember = substr(credits, RSTART + 1, RLENGTH - 2)
        # print "castMember = " castMember
        numFields = split(castMember, fld, "\"")
        print "person_role: " fld[4]
        print "person_name: " fld[8]
        print "person_URL: " fld[12]
        print "character_name: " fld[16]

        credits = substr(credits, RSTART + RLENGTH)
    }
}
