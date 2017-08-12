#! /bin/bash

# Time the primary variants of shell scripts that make spreadsheets

echo "==> time ./makeMHzSpreadsheet.sh -td" ; date
time ./makeMHzSpreadsheet.sh -td
echo ""
echo "---"
echo ""
echo "==> time ./makeMHzSpreadsheet.sh -tld" ; date
time ./makeMHzSpreadsheet.sh -tld
echo ""
echo "---"
echo ""

echo "==> time ./makeAcornSpreadsheet.sh -td" ; date
time ./makeAcornSpreadsheet.sh -td
echo ""
echo "---"
echo ""
echo "==> time ./makeAcornSpreadsheet.sh -tld" ; date
time ./makeAcornSpreadsheet.sh -tld
