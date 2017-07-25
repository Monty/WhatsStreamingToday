#! /bin/bash

# Time the primary variants of shell scripts that make spreadsheets

echo "==> time ./makeMHzSpreadsheet.sh -td"
time ./makeMHzSpreadsheet.sh -td
echo ""
echo "---"
echo ""
echo "==> time ./makeMHzSpreadsheet.sh -tld"
time ./makeMHzSpreadsheet.sh -tld
echo ""
echo "---"
echo ""

echo "==> time ./makeAcornSpreadsheet.sh -td"
time ./makeAcornSpreadsheet.sh -td
echo ""
echo "---"
echo ""
echo "==> time ./makeAcornSpreadsheet.sh -tld"
time ./makeAcornSpreadsheet.sh -tld
