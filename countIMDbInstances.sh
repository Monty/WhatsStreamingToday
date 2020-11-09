#!/usr/bin/env bash
# Count the instances of any "word" in downloaded IMDb data files

# INVOCATION:
#    countIMDbInstances.sh tt1809792
#    countIMDbInstances.sh nm4257020
#    countIMDbInstances.sh Montalbano

for file in title.basics.tsv.gz title.akas.tsv.gz title.principals.tsv.gz title.crew.tsv.gz \
    title.episode.tsv.gz name.basics.tsv.gz; do
    if [ -e "$file" ]; then
        count=$(rg -wcz $1 $file)
        if [ "$count" == "" ]; then
            count=0
        fi
        printf "%-10s\t%5d\t%s\n" $1 $count $file
    fi
done
