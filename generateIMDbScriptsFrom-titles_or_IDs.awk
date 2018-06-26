{
    title = $0
    if (match (title, /, The"$/)) {
        sub (/^"/,"\"The ", title)
        sub (/, The"$/,"\"", title)
    }

    if (FILENAME ~ /Acorn/) 
        KEY = "A"
    if (FILENAME ~ /BBox/) 
        KEY = "B"
    if (FILENAME ~ /MHz/) 
        KEY = "M"
    if (FILENAME ~ /Watched/) 
        KEY = "W"

    printf ("echo ==\\> %sT %03d: %s\n", KEY, NR, title) >> TITLES_SCRIPT
    printf ("./getIMDbInfoFrom-title_or_ID.py %s\n",title) >> TITLES_SCRIPT
    printf ("echo\n\n") >> TITLES_SCRIPT

    printf ("echo ==\\> %sI %03d: %s\n", KEY, NR, title) >> ID_SCRIPT
    printf ("./getIMDb_IDsFrom-title.py %s | head -7\n",title) >> ID_SCRIPT
    printf ("echo\n\n") >> ID_SCRIPT
}

END {
    nflds = split (TITLES_SCRIPT,fld,"/")
    printf ("# End of %s\n", fld[nflds]) >> TITLES_SCRIPT
    nflds = split (ID_SCRIPT,fld,"/")
    printf ("# End of %s\n", fld[nflds]) >> ID_SCRIPT
}

