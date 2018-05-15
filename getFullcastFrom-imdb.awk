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

    if (Cast == "" && Directors == "" && Writers == "")
        next

    if (NR == 1)
        next

    if (Cast != "") {
        gsub (/[[:blank:]]{3,99}\(uncredited\)/," (uncredited)",Cast)
        nflds1 = split (Cast,fld,/[[:blank:]]{3,99}/)
        type = "Actor"
        person = fld[1]
        role = fld[3]
        sub (/\302\240/,"",role)
        episodes = fld[4]
        nflds2 = split (episodes,fld,/,/)
        num_episodes = fld[1]
        sub (/ episodes?/,"",num_episodes)
        episode_years = fld[2]
        sub (/ /,"",episode_years)
    }

    if (Directors != "") {
        nflds1 = split (Directors,fld,/[[:blank:]]{3,99}/)
        type = "Director"
        role = ""
        person = fld[1]
        episodes = fld[3]
        gsub (/[()]/,"",episodes)
        nflds2 = split (episodes,fld,/,/)
        num_episodes = fld[1]
        sub (/ episodes?/,"",num_episodes)
        episode_years = fld[2]
        sub (/ /,"",episode_years)
    }

    if (Writers != "") {
        nflds1 = split (Writers,fld,/[[:blank:]]{3,99}/)
        type = "Writer"
        role = ""
        person = fld[1]
        episodes = fld[3]
        gsub (/[()]/,"",episodes)
        nflds2 = split (episodes,fld,/,/)
        num_episodes = fld[1]
        sub (/ episodes?/,"",num_episodes)
        episode_years = fld[2]
        sub (/ /,"",episode_years)
    }

    printf ("%d - %s %s\t%s\t%s\t%s\t%s\t%s\n",nflds1,Title,Years,person,type,role,num_episodes,episode_years)

}
