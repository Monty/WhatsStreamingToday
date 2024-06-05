#!/usr/bin/env bash
# Create a .csv spreadsheet of shows available on Walter Presents

# trap ctrl-c and call cleanup
trap cleanup INT
#
function cleanup() {
    printf "\n"
    exit 130
}

# Make sure we are in the correct directory
DIRNAME=$(dirname "$0")
cd $DIRNAME

# Make sort consistent between Mac and Linux
export LC_COLLATE="C"

# Create some timestamps
DATE_ID="-$(date +%y%m%d)"
LONGDATE="-$(date +%y%m%d.%H%M%S)"

# Make sure we can execute curl.
if [ ! -x "$(which curl 2>/dev/null)" ]; then
    printf "[Error] Can't run curl. Install curl and rerun this script.\n"
    printf "        To test, type:  curl -Is https://github.com/ | head -5\n"
    exit 1
fi

# Make sure network is up and Walter Presents site is reachable
BROWSE_URL="https://www.pbs.org/franchise/walter-presents/"
if ! curl -o /dev/null -Isf $BROWSE_URL; then
    printf "[Error] $BROWSE_URL isn't available, or your network is down.\n"
    printf "        Try accessing $BROWSE_URL in your browser.\n"
    exit 1
fi

SPREADSHEET="Walter-Presents_Shows$DATE_ID.csv"

printf "Show Title\tEpisodes\n" >$SPREADSHEET

curl -sS $BROWSE_URL | awk -f getWalterFromBrowsePage.awk | sort >>$SPREADSHEET

printf "==> $SPREADSHEET\n"
