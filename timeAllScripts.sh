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
# The first time this is run, there are missing episodes. Running it twice seem to fix the problem.
time ./makeAcornSpreadsheet.sh -t
time ./makeAcornSpreadsheet.sh -t
echo ""
echo "----------------------------------------"
echo "==> time ./makeAcornSpreadsheet.sh -tld"
date
time ./makeAcornSpreadsheet.sh -tld
echo ""

echo "----------------------------------------"
echo "==> time ./makeBBoxFromSitemap.sh -td"
date
time ./makeBBoxFromSitemap.sh -td
echo ""

echo "========================================"
