# Grab the numbr of episodes from an MHz section such as:
# <meta itemprop="numberOfEpisodes" content="8" />
#        <h2 class="site-font-secondary-color site-font-primary-family content-label padding-top-medium grid-padding-right">
#          18 Episodes
#        </h2>

# Extract only the number of episodes
/<h2 class=.*content-label/,/h2>/ {
    s/^ *//
    /^<h2 class=/D
    /^<\/h2>/D
    s/ Episode.*//
    s/^/+/
    p
}
