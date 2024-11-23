# Process data from getOPB.js
/meta property="og:title" content=/ { print }

/link rel="canonical" href=/ { print }

/"description": "/ { print }

/"genre": "/ { print }

/"numberOfSeasons": / { print }

/"TVSeason", / { print }

/^                              alt="/ { print }

/class="VideoDetailThumbnail_video_description/, /<\/p>/ { print }

# Don't need svg data
/<svg/, /<\/svg/ { next }

/Copyright ©/ {
    print
    exit
}
