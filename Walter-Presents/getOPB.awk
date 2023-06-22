# Process data from getWalter.js and PBS-only.csv

/data-title="/ {
    split ($0,fld,"\"")
    showTitle = fld[2]
}

/data-show-slug=/ {
    split ($0,fld,"\"")
    showSlug = "https://www.pbs.org/show/" fld[2]
    printf ("%s\t%s\n", showSlug, showTitle)
}

# Process data from getOPB.js

/meta property="og:title" content=/ {
    print
}

/link rel="canonical" href=/ {
    print
}

/"description": "/ {
    print
}

/"genre":/ {
    print
}

/id="splide01-slide/,/<div class="vertical-sponsorship">/ { print }

/<!-- start medium-rectangle-half-page -->/ {
    print
    exit
}
