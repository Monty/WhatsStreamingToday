{
    title = $0
    if (match (title, /, The"$/)) {
        sub (/^"/,"\"The ", title)
        sub (/, The"$/,"\"", title)
    }
    printf ("echo ==\\> %3d %s\n",NR,title) >> TITLES_SCRIPT
    printf ("./getIMDbScriptsFrom-titles.py %s\n",title) >> TITLES_SCRIPT
    printf ("echo \n\n") >> TITLES_SCRIPT

    printf ("echo ==\\> %3d %s\n",NR,title) >> ID_SCRIPT
    printf ("./searchForIMDbMovie.py %s | head -7\n",title) >> ID_SCRIPT
    printf ("echo \n\n") >> ID_SCRIPT
}

