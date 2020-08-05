#!/usr/bin/env bash

# Time the primary variants of shell scripts that make spreadsheets
# in order from fastest to slowest so first results come in quickly

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
