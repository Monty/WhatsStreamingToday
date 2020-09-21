#!/usr/bin/env bash
# Print the first 20 lines of any downloaded IMDb .gz files
#
# See https://www.imdb.com/interfaces/ for a description of IMDb Datasets

for file in $(ls *.gz); do
    echo "File = $file"
    gzcat $file | head -20
    echo ""
done
