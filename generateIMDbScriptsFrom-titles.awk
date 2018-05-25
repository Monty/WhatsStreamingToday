{
    title = $0
    if (match (title, /, The"$/)) {
        sub (/^"/,"\"The ", title)
        sub (/, The"$/,"\"", title)
    }
    printf ("echo ==\\> %3d %s\n",NR,title) >> FIRST_SCRIPT
    # printf ("get_first_movie.py %s | awk '/^    Best match/,/^Language:/'\n",title) >> FIRST_SCRIPT
    printf ("./getIMDbCastInfo.py %s\n",title) >> FIRST_SCRIPT
    printf ("echo \n\n") >> FIRST_SCRIPT

    printf ("echo ==\\> %3d %s\n",NR,title) >> SEARCH_SCRIPT
    printf ("./searchForIMDbMovie.py %s | head -7\n",title) >> SEARCH_SCRIPT
    printf ("echo \n\n") >> SEARCH_SCRIPT
}

