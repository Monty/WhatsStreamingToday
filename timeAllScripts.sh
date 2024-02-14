#!/usr/bin/env bash
# Time shell scripts that make spreadsheets -- fastest to slowest so first results are available quickly

PATH=${PATH}:/usr/local/bin

printf "========================================\n" | tee /dev/stderr
printf "==> time ./makeBBoxFromSitemap.sh -td\n" | tee /dev/stderr
date | tee /dev/stderr
time ./makeBBoxFromSitemap.sh -td
printf "\n" | tee /dev/stderr

printf -- "----------------------------------------\n" | tee /dev/stderr
printf "==> time ./makeMHzFromSitemap.sh -td\n" | tee /dev/stderr
date | tee /dev/stderr
time ./makeMHzFromSitemap.sh -td
printf "\n" | tee /dev/stderr

printf -- "----------------------------------------\n" | tee /dev/stderr
printf "==> time ./makeAcornFromBrowsePage.sh -td\n" | tee /dev/stderr
date | tee /dev/stderr
time ./makeAcornFromBrowsePage.sh -td
printf "\n" | tee /dev/stderr

printf -- "----------------------------------------\n" | tee /dev/stderr
printf "==> time Walter-Presents/makeOPB.sh -td\n" | tee /dev/stderr
date | tee /dev/stderr
time Walter-Presents/makeOPB.sh -td
printf "\n" | tee /dev/stderr

printf -- "----------------------------------------\n"
printf "==> time Walter-Presents/addEpisodeDescriptions.sh -d\n" | tee /dev/stderr
date | tee /dev/stderr
time Walter-Presents/addEpisodeDescriptions.sh -d
printf "\n" | tee /dev/stderr

date | tee /dev/stderr

exit

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
