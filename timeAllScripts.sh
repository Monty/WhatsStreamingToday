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

printf -- "----------------------------------------\n"
printf "==> time ./makeIMDbFromFiles.sh\n"
date
time ./makeIMDbFromFiles.sh
printf "\n"

printf "========================================\n"
