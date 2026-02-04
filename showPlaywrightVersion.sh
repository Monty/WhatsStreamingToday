#!/usr/bin/env bash

# Check if Playwright is installed, then print version numbers

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
