#!/usr/bin/env bash
# Time shell scripts that make spreadsheets -- fastest to slowest so first results are available quickly

# Make sure we can execute the rust utilities rg, sd, and zet.
# rustc rg zet
if [ ! -x "$(which rustc 2>/dev/null)" ] ||
    [ ! -x "$(which rg 2>/dev/null)" ] ||
    [ ! -x "$(which sd 2>/dev/null)" ] ||
    [ ! -x "$(which zet 2>/dev/null)" ]; then
    printf "==> [Error] The programs rust, ripgrep, sd, and zet are required.\n"
    printf "For installation instructions see: \n"
    printf "    https://www.rust-lang.org \n"
    printf "    https://crates.io/crates/ripgrep \n"
    printf "    https://crates.io/crates/sd \n"
    printf "    https://crates.io/crates/zet \n"
    exit 1
fi

PATH=/Users/monty/.volta/bin:${PATH}:/usr/local/bin
printf "==> PATH = ${PATH}\n\n" | sd ':' '\n' | tee /dev/stderr

printf "========================================\n" | tee /dev/stderr
printf "==> time ./makeOPB.sh -td\n" | tee /dev/stderr
date | tee /dev/stderr
time ./makeOPB.sh -td
printf "\n" | tee /dev/stderr

printf -- "----------------------------------------\n" | tee /dev/stderr
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

date | tee /dev/stderr

exit

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
