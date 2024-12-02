# Process data from getOPB.js
/meta property="og:title" content=/ { print }

/link rel="canonical" href=/ { print }

/"description": "/ { print }

/"genre": "/ { print }

/"containsSeason": \[\{/ {
    sub(/"containsSeason": \[/, "  ")
    sub(/\]/, "")
    print
    next
}

/"numberOfSeasons": / { print }

/"TVSeason", / { print }

/class="VideoDetailThumbnail_video_title/, /<\/p>/ { print }

/class="VideoDetailThumbnail_video_description/, /<\/p>/ { print }

# Don't need svg data
/<svg/, /<\/svg/ { next }

/Copyright ©/ {
    print
    exit
}
