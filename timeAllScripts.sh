#!/usr/bin/env bash

# Time the primary variants of shell scripts that make spreadsheets

echo "========================================"
echo "==> time ./makeMHzFromSitemap.sh -td"
date
time ./makeMHzFromSitemap.sh -td
echo ""

echo "----------------------------------------"
echo "==> time ./makeAcornSpreadsheet.sh -t"
date
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
