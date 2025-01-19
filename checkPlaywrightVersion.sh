#!/usr/bin/env bash

# Chack if playwright is installed, then print version numbers

if [ -d "$HOME/Library/Caches/ms-playwright/" ]; then
    printf "Your installed playwright and chromium browser versions are:\n"
    npx playwright --version
    node chromium-version.js
    printf "\nYou can check the playwright release notes to find out the latest version.\n"
    printf "https://playwright.dev/docs/release-notes\n"
else
    printf "It appears playwright is not installed. See:\n"
    printf "https://playwright.dev/docs/intro\n"
fi
