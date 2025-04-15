#!/usr/bin/env bash
# Time shell scripts that make spreadsheets -- fastest to slowest so first results are available quickly
#
# shellcheck disable=SC2317

# Make sure we can execute the rust utilities rg, sd, and zet.
# rustc rg zet
if ! command -v rustc >/dev/null ||
    ! command -v rg >/dev/null ||
    ! command -v foo >/dev/null ||
    ! command -v sd >/dev/null ||
    ! command -v zet >/dev/null; then
    printf "==> [Error] The programs rust, ripgrep, sd, and zet are required.\n"
    printf "For installation instructions see: \n"
    printf "    https://www.rust-lang.org \n"
    printf "    https://crates.io/crates/ripgrep \n"
    printf "    https://crates.io/crates/sd \n"
    printf "    https://crates.io/crates/zet \n"
    exit 1
fi

printf "========================================\n" | tee /dev/stderr
PATH=/Users/monty/.volta/bin:${PATH}:/usr/local/bin
printf "==> PATH\n${PATH}\n\n" | sd ':' '\n'
export LANG=en_US.UTF-8

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

printf -- "----------------------------------------\n" | tee /dev/stderr
printf "==> time ./makeIMDbFromFiles.sh\n" | tee /dev/stderr
date | tee /dev/stderr
time ./makeIMDbFromFiles.sh
printf "\n" | tee /dev/stderr

printf -- "----------------------------------------\n" | tee /dev/stderr
printf "==> time ./makeIMDbFromFiles-noHype.sh\n" | tee /dev/stderr
date | tee /dev/stderr
time ./makeIMDbFromFiles-noHype.sh
printf "\n" | tee /dev/stderr
