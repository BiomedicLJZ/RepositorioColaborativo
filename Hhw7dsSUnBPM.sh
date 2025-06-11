#!/bin/bash

# === Configuration ===
original_file="$1"

# Check if file was provided and exists
if [[ -z "$original_file" || ! -f "$original_file" ]]; then
    echo "Usage: $0 <filename>"
    echo "Error: You must provide a valid file path."
    exit 1
fi

# === Generate a random number between 1 and 6 ===
random_number=$(( ( RANDOM % 6 ) + 1 ))
echo "Random number generated: $random_number"

# === If the number is 6, rename the file ===
if [[ "$random_number" -eq 6 ]]; then
    # Generate gibberish name using /dev/urandom, base64, and removing special characters
    gibberish_name=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 12)

    # Extract file extension, if any
    extension="${original_file##*.}"
    if [[ "$original_file" == *.* && "$extension" != "$original_file" ]]; then
        gibberish_name="${gibberish_name}.${extension}"
    fi

    mv "$original_file" "$gibberish_name"
    echo "File renamed to: $gibberish_name"
else
    echo "File was not renamed."
fi

