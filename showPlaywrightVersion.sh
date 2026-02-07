#!/usr/bin/env bash

# Check if Playwright is installed, then print version numbers

# Prevent cascading or pipe failures
set -euo pipefail

# trap and locate errors that might arise from pipefail
trap 'printf "${ERROR} at or near line %s:\n\t%s\n" \
    "$LINENO" "$BASH_COMMAND" >&2' ERR

# trap ctrl-c and SIGTERM -- call cleanup and exit
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
#
function cleanup() {
    stty sane
    printf "\n"
}

if command -v playwright >/dev/null; then
    printf "Your installed Playwright and chromium browser versions are:\n"

    if ! playwright --version; then
        printf "Error: Failed to get Playwright version\n"
        exit 1
    fi

    # Check if chromium-version.js exists before running it
    if [[ -f "chromium-version.js" ]]; then
        if ! node chromium-version.js; then
            printf "Error: Failed to get Chromium version\n"
            exit 1
        fi
    else
        printf "Warning: chromium-version.js not found\n"
    fi

    printf "\nYou can check the Playwright release notes to find out the latest version.\n"
    printf "https://playwright.dev/docs/release-notes\n"
else
    printf "It appears Playwright is not installed. See:\n"
    printf "https://playwright.dev/docs/intro\n"
fi
