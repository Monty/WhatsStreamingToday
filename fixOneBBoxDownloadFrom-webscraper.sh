#! /bin/bash
# Create a canonical form of a webscraper download. Simplifies cutting specific fields.
# Useful for comparing files. Not useful for many purposes as it only deletes the first field
# and know nothing about their useless fields.

# Join broken lines, get rid of useless 'web-scraper-order' field, change comma-separated to
# tab separated, sort into useful order
awk -f fixExtraLinesFrom-webscraper.awk $1 | cut -f 2- -d "," | csvformat -T |
    grep '/us/' | sort -df --field-separator=$'\t' --key=1,1
