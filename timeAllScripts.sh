#!/usr/bin/env bash
# Time shell scripts that make spreadsheets -- fastest to slowest so first results are available quickly

echo "========================================"
echo "==> time ./makeBBoxFromSitemap.sh -td"
date
time ./makeBBoxFromSitemap.sh -td
echo ""

echo "----------------------------------------"
echo "==> time ./makeMHzFromSitemap.sh -td"
date
time ./makeMHzFromSitemap.sh -td
echo ""

echo "----------------------------------------"
echo "==> time ./makeAcornFromBrowsePage.sh -td"
date
time ./makeAcornFromBrowsePage.sh -td
echo ""

echo "========================================"
