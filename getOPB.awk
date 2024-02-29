# Process data from getOPB.js
/meta property="og:title" content=/ { print }

/link rel="canonical" href=/ { print }

/"description": "/ { print }

/"genre":/ { print }

# Don't need svg data
/<svg/, /<\/svg/ { next }

/id="splide01-slide/, /<div class="vertical-sponsorship">/ { print }

/<!-- start medium-rectangle-half-page -->/ {
    print
    exit
}
