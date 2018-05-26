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

    printf ("echo ==\\> %sT %3d: %s\n", KEY, NR, title) >> TITLES_SCRIPT
    printf ("./getIMDbInfoFrom-titles.py %s\n",title) >> TITLES_SCRIPT
    printf ("echo \n\n") >> TITLES_SCRIPT

    printf ("echo ==\\> %sI %3d: %s\n", KEY, NR, title) >> ID_SCRIPT
    printf ("./getIMDb_IDsFrom-titles.py %s | head -7\n",title) >> ID_SCRIPT
    printf ("echo \n\n") >> ID_SCRIPT
}

