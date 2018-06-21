#!/usr/bin/env bash

# Time the primary variants of shell scripts that make spreadsheets

echo "========================================"
echo "==> time ./makeMHzSpreadsheet.sh -t"
date
time ./makeMHzSpreadsheet.sh -t
echo ""
echo "----------------------------------------"
echo "==> time ./makeMHzSpreadsheet.sh -tld"
date
time ./makeMHzSpreadsheet.sh -tld
echo ""

echo "----------------------------------------"
echo "==> time ./makeAcornSpreadsheet.sh -t"
date
# The first time this is run, there are missing episodes. Running it twide seem to fix the problem.
time ./makeAcornSpreadsheet.sh -t
time ./makeAcornSpreadsheet.sh -t
echo ""
echo "----------------------------------------"
echo "==> time ./makeAcornSpreadsheet.sh -tld"
date
time ./makeAcornSpreadsheet.sh -tld
echo ""

# csvformat breaks in scripts run by a launchd.plist
# It can't find csvformat and can't deal with UTF-8
if [ ! -e "$(which csvformat 2>/dev/null)" ]; then
    PATH=${PATH}:/usr/local/bin
fi
#
export LC_ALL=en_US.UTF-8
#
echo "----------------------------------------"
echo "==> time ./makeBBoxSpreadsheet.sh -td"
date
time ./makeBBoxSpreadsheet.sh -td
echo ""

echo "========================================"
