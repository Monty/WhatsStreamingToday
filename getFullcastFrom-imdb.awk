BEGIN {
    FS = "\t"
}

{
    web_scraper_start_url = $1
    Title = $2
    Years = $3
    Cast = $4
    Directors = $5
    Writers = $6
    person = ""
    role = ""
    num_episodes = ""
    episode_years = ""

    if (Cast == "" && Directors == "" && Writers == "")
        next

    if (NR == 1)
        next

    if (Cast != "") {
        type = "Actor"
        gsub (/[[:blank:]]{3,99}\(uncredited\)/," (uncredited)",Cast)
        gsub (/[[:blank:]]{3,99}\/ \.\.\./," / ...",Cast)
        extra = sub (/\(extra\) ?/,"",Cast)
        if (extra != 0)
            type = type " (extra)"
        uncredited = sub (/\(uncredited\) ?/,"",Cast)
        if (uncredited != 0)
            type = type " (uncredited)"
        nflds1 = split (Cast,fld,/[[:blank:]]{3,99}/)
        person = fld[1]
        role = fld[3]
        sub (/\302\240/,"",role)
        episodes = fld[4]
        if (episodes !~ /episodes?/) {
            person = person " " episodes
        } else {
            nflds2 = split (episodes,fld,/,/)
            num_episodes = fld[1]
            sub (/ episodes?/,"",num_episodes)
            episode_years = fld[2]
            sub (/ /,"",episode_years)
        }
    }

    if (Directors != "") {
        type = "Director"
        nflds1 = split (Directors,fld,/[[:blank:]]{3,99}/)
        person = fld[1]
        episodes = fld[3]
        uncredited = sub (/\(uncredited\) /,"",episodes)
        if (uncredited != 0)
            type = type " (uncredited)"
        gsub (/[()]/,"",episodes)
        nflds2 = split (episodes,fld,/,/)
        num_episodes = fld[1]
        sub (/ episodes?/,"",num_episodes)
        episode_years = fld[2]
        sub (/ /,"",episode_years)
    }

    if (Writers != "") {
        type = "Writer"
        nflds1 = split (Writers,fld,/[[:blank:]]{3,99}/)
        person = fld[1]
        parens = fld[3]
        nparens = split (parens,fld,/[()]/)
        for ( i = 2; i < nparens-1; i+=2 ) {
            if (fld[i] != " ") {
                type = type " (" fld[i] ")"
            }
        }
        episodes = fld[nparens-1]
        if (episodes !~ /episodes?/) {
            type = type " (" episodes ")"
        } else {
            nflds2 = split (episodes,fld,/,/)
            num_episodes = fld[1]
            sub (/ episodes?/,"",num_episodes)
            episode_years = fld[2]
            sub (/ /,"",episode_years)
        }
    }

    printf ("%s %s\t%s\t%s\t%s\t%s\t%s\n",Title,Years,person,type,role,num_episodes,episode_years)

}
