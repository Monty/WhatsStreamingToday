#! /bin/bash

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
time ./makeAcornSpreadsheet.sh -t
echo ""
echo "----------------------------------------"
echo "==> time ./makeAcornSpreadsheet.sh -tld"
date
time ./makeAcornSpreadsheet.sh -tld
echo ""
echo "========================================"
