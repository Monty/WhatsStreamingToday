#!/usr/bin/env zsh
#
# Upload and format the latest versions of streaming shows and episodes

DIRNAME=$(dirname "$0")
cd "$DIRNAME" || exit

# Load private local tokens safely
# shellcheck disable=SC1091 # ~/.tokens is a local file
if [[ -f "$HOME/.tokens" ]]; then
    source "$HOME/.tokens"
fi

# Fallback or check if the token environment variable was successfully loaded
if [[ -z $TV_SHEETS_API_URL ]]; then
    echo "Error: TV_SHEETS_API_URL is not set. Please check your ~/.tokens file."
    exit 1
fi

# Assign the secure environment variable
API_URL="$TV_SHEETS_API_URL"

typeset -A CSV_FILES
CSV_FILES=(
    ["acorn_shows"]="$(find Acorn_TV_Shows-*csv 2>/dev/null | tail -1)"
    ["acorn_episodes"]="$(find Acorn_TV_ShowsEpisodes-*csv 2>/dev/null | tail -1)"
    ["bbox_shows"]="$(find BBox_TV_Shows-*csv 2>/dev/null | tail -1)"
    ["bbox_episodes"]="$(find BBox_TV_ShowsEpisodes-*csv 2>/dev/null | tail -1)"
    ["mhz_shows"]="$(find MHz_TV_Shows-*csv 2>/dev/null | tail -1)"
    ["mhz_episodes"]="$(find MHz_TV_ShowsEpisodes-*csv 2>/dev/null | tail -1)"
    ["opb_shows"]="$(find OPB_TV_Shows-*csv 2>/dev/null | tail -1)"
    ["opb_episodes"]="$(find OPB_TV_ShowsEpisodes-*csv 2>/dev/null | tail -1)"
)

echo "Starting batch import and formatting pipeline (Parallel)..."

for target in "${(k)CSV_FILES[@]}"; do
    file_path="${CSV_FILES[$target]}"

    if [[ -f $file_path ]]; then
        echo "Launching background upload for $target ($file_path)..."

        # The ( ... ) & block forces curl to run in the background asynchronously
        (
            response=$(curl -s -L --data-binary @"$file_path" "${API_URL}?target=${target}")
            echo "Finished $target -> Response: $response"
        ) &
    else
        echo "Warning: File not found for $target, skipping."
    fi
done

echo "Waiting for all background transfers to finish processing..."
wait
echo "All sync tasks completed."
