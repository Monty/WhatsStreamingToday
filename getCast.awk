# Extract cast & crew from MHz episode files

# INVOCATION:
#    awk -v ERRORS=$ERRORS -f getCast.awk >>$RAW_CREDITS

# 21     <meta property="og:url" content="https://watch.mhzchoice.com/captain-marleau/season:2/...
#
# 1135           data-meta-field-name="casts"
# 1136           data-meta-field-value="Corinne Masiero"
# 1137           data-track-event="metadata_click_cast"
# 1138           data-text-no-results="No results"
# 1139           data-text-load-more="Load More"
# 1140         >
# 1141           Corinne Masiero
# 1142         </a>
# 1143         <span class="small-8 capitalize">Captain Marleau</span>
#
# 1219           data-meta-field-name="crew"
# 1220           data-meta-field-value="Josée Dayan"
# 1221           data-track-event="metadata_click_crew"
# 1222           data-text-no-results="No results"
# 1223           data-text-load-more="Load More"
# 1224         >
# 1225           Josée Dayan
# 1226         </a>
# 1227         <span class="small-8 capitalize">director</span>

/<meta property="og:url" content/ {
    split ($0,fld,"/")
    title = fld[4]
    split ($0,fld,"\"")
    shortURL = fld[4]
    sub (/.*watch/,"watch",shortURL)
}

/data-meta-field-name="casts"/,/<span class="small-8 capitalize">/ {
    if ($0 ~ /data-meta-field-value=/) {
        tvShowType = "tv_show"
        person_role = "actor"
        split ($0,fld,"\"")
        person_name = fld[2]
        sub (/\.$/,"",person_name)
        next
    }
    if ($0 ~ /<span class="small-8 capitalize/) {
        split ($0,fld,"[<>]")
        char_name = fld[3]
        if (match (person_name, " and ") || match (person_name, " & ")) {
            pname = substr(person_name,1,RSTART-1)
            sub (/\.$/,"",pname)
            person_name = substr(person_name,RSTART+RLENGTH)
            printf ("%s\t%s\t%s\t%s\t%s\n", pname, person_role, tvShowType, title, char_name)
            if (pname !~ " ")
                print "==> Single name '" pname "' in " shortURL >> ERRORS
        }
        # Special case
        if (person_name ~ /Hendrik Toompere/)
            person_name = "Hendrik Toompere Jr."
        #
        printf ("%s\t%s\t%s\t%s\t%s\n", person_name, person_role, tvShowType, title, char_name)
        if (person_name !~ " ")
            print "==> Single name '" person_name "' in " shortURL >> ERRORS
        person_role = ""
        person_name = ""
        char_name = ""
        next
    }
}

/data-meta-field-name="crew"/,/<span class="small-8 capitalize">/ {
        if ($0 ~ /data-meta-field-value=/) {
        tvShowType = "tv_show"
        split ($0,fld,"\"")
        person_name = fld[2]
        # Special case
        if (person_name ~ /Manetti Bros/)
            person_name = "The Manetti Bros."
        #
    }
    if ($0 ~ /<span class="small-8 capitalize/) {
        split ($0,fld,"[<>]")
        person_role = fld[3]
        printf ("%s\t%s\t%s\t%s\t%s\n", person_name, person_role, tvShowType, title, char_name)
        person_role = ""
        person_name = ""
    }
}
