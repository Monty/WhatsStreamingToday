#!/usr/bin/env bash
# Time shell scripts that make spreadsheets -- fastest to slowest so first results are available quickly
#
# shellcheck disable=SC2317

# Make sure we can execute the rust utilities rg, sd, and zet.
if ! command -v rg >/dev/null ||
    ! command -v sd >/dev/null ||
    ! command -v zet >/dev/null; then
    printf "==> [Error] The programs ripgrep, sd, and zet are required.\n"
    printf "For installation instructions see: \n"
    printf "    https://www.rust-lang.org  (if building with cargo)\n"
    printf "    https://crates.io/crates/ripgrep \n"
    printf "    https://crates.io/crates/sd \n"
    printf "    https://crates.io/crates/zet \n"
    exit 1
fi

printf "========================================\n" | tee /dev/stderr
export LANG=en_US.UTF-8
SECONDS=0 # bash builtin: seconds since it was set

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

MINS=$((SECONDS / 60))
SECS=$((SECONDS % 60))
[ "$MINS" -eq 1 ] && MIN_UNIT=minute || MIN_UNIT=minutes
[ "$SECS" -eq 1 ] && SEC_UNIT=second || SEC_UNIT=seconds
printf "==> Completed at %s in %d %s %d %s\n" "$(date)" \
    "$MINS" "$MIN_UNIT" "$SECS" "$SEC_UNIT" | tee /dev/stderr

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
