#!/bin/sh
set -e

# Usage: download_and_verify <url> <checksum>
# Downloads a file, verifies its sha256 checksum, and outputs the local path.
download_and_verify() {
    local url="$1"
    local expected_checksum="$2"
    local filename=$(basename "$url")
    local output_path="/tmp/${filename}"

    echo "Downloading $filename..." >&2
    curl -fsSL -o "${output_path}" "$url"

    echo "Verifying checksum for $filename..." >&2
    if ! echo "${expected_checksum}  ${output_path}" | sha256sum -c --status -; then
        echo "Checksum verification failed for ${filename}." >&2
        exit 1
    fi
    echo "${output_path}"
}

# Usage: download_resource <url> <filename>
# Downloads a resource file and places it in RESOURCES_DIR.
download_resource() {
    local url="$1"
    local filename="$2"
    echo "Downloading resource $filename"
    curl -fsSL -o "${RESOURCES_DIR}/${filename}" "$url"
}
