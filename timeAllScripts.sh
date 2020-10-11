#!/usr/bin/env bash
# Time shell scripts that make spreadsheets -- fastest to slowest so first results are available quickly

printf "========================================\n"
printf "==> time ./makeBBoxFromSitemap.sh -td\n"
date
time ./makeBBoxFromSitemap.sh -td
printf "\n"

printf -- "----------------------------------------\n"
printf "==> time ./makeMHzFromSitemap.sh -td\n"
date
time ./makeMHzFromSitemap.sh -td
printf "\n"

printf -- "----------------------------------------\n"
printf "==> time ./makeAcornFromBrowsePage.sh -td\n"
date
time ./makeAcornFromBrowsePage.sh -td
printf "\n"

# Make sure we can execute rg.
if [ ! -x "$(which rg 2>/dev/null)" ]; then
    printf "[Warning] Can't run rg. Skipping makeIMDbFromFiles.\n"
    printf "\n"
    printf "========================================\n"
    exit 1
fi

printf -- "----------------------------------------\n"
printf "==> time ./makeIMDbFromFiles.sh\n"
date
time ./makeIMDbFromFiles.sh
printf "\n"

printf -- "----------------------------------------\n"
printf "==> time ./makeIMDbFromFiles-noHype.sh\n"
date
time ./makeIMDbFromFiles-noHype.sh
printf "\n"

printf "========================================\n"
