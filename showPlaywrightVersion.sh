#!/usr/bin/env bash

# Check if playwright is installed, then print version numbers

if [ -d "${HOME}/Library/Caches/ms-playwright/" ]; then
    printf "Your installed playwright and chromium browser versions are:\n"

    # Run playwright version command with error handling
    if ! npx playwright --version; then
        printf "Error: Failed to get playwright version\n"
        exit 1
    fi

    # Check if chromium-version.js exists before running it
    if [ -f "chromium-version.js" ]; then
        if ! node chromium-version.js; then
            printf "Error: Failed to get Chromium version\n"
            exit 1
        fi
    else
        printf "Warning: chromium-version.js not found\n"
    fi

    printf "\nYou can check the playwright release notes to find out the latest version.\n"
    printf "https://playwright.dev/docs/release-notes\n"
else
    printf "It appears playwright is not installed. See:\n"
    printf "https://playwright.dev/docs/intro\n"
fi
