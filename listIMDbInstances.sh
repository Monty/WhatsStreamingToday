#!/usr/bin/env bash
# Print the instances of any "word" in downloaded IMDb data files

# INVOCATION:
#    listIMDbInstances.sh tt1809792
#    listIMDbInstances.sh nm4257020
#    listIMDbInstances.sh Montalbano

for file in title.basics.tsv.gz title.akas.tsv.gz title.principals.tsv.gz title.crew.tsv.gz \
    title.episode.tsv.gz name.basics.tsv.gz; do
    if [ -e "$file" ]; then
        printf "==> $file\n"
        rg -wSNz "$1" "$file"
        printf "\n"
    fi
done
