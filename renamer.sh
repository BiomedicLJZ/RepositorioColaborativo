#!/bin/bash
# Script: recursive_rename_if_six.sh
# Description: Recursively scans all files in the current directory and subdirectories.
# For each file, generates a random number from 1 to 10.
# If the number is 6, the file is renamed to a gibberish name (preserving the extension).

# Function to generate a gibberish filename
generate_gibberish_name() {
    head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 12
}

# Main recursive loop
find . -type f | while IFS= read -r file; do
    # Skip hidden files or directories like .git
    [[ "$file" =~ ^\./\. ]] && continue

    RANDOM_NUMBER=$(( (RANDOM % 10) + 1 ))
    echo "File: '$file' → Random number: $RANDOM_NUMBER"

    if [ "$RANDOM_NUMBER" -eq 6 ]; then
        DIRNAME=$(dirname "$file")
        BASENAME=$(basename "$file")

        EXTENSION="${BASENAME##*.}"
        FILENAME_WITHOUT_EXT="${BASENAME%.*}"

        # Determine if there is an actual extension
        if [[ "$BASENAME" == "$EXTENSION" ]]; then
            # No extension
            NEW_NAME=$(generate_gibberish_name)
        else
            # With extension
            NEW_NAME="$(generate_gibberish_name).${EXTENSION}"
        fi

        # Avoid overwriting existing files
        TARGET_PATH="${DIRNAME}/${NEW_NAME}"
        while [ -e "$TARGET_PATH" ]; do
            NEW_NAME="$(generate_gibberish_name).${EXTENSION}"
            TARGET_PATH="${DIRNAME}/${NEW_NAME}"
        done

        echo "→ Renaming '$file' to '$TARGET_PATH'"
        mv "$file" "$TARGET_PATH"
    fi
done

