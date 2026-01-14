#!/bin/sh
set -e

# Usage: download_jar <url>
# Downloads a JAR file, verifies its sha1 checksum, and places it in LIB_DIR.
download_jar() {
    local url="$1"
    local filename=$(basename "$url")
    echo "Downloading $filename"
    curl -fsSL -o "${LIB_DIR}/${filename}" "$url"
    curl -fsSL -o "${LIB_DIR}/${filename}.sha1" "$url.sha1"
    echo "$(cat ${LIB_DIR}/${filename}.sha1)  ${LIB_DIR}/${filename}" | sha1sum -c -
    rm "${LIB_DIR}/${filename}.sha1"
}

# Usage: download_resource <url> <filename>
# Downloads a resource file and places it in RESOURCES_DIR.
download_resource() {
    local url="$1"
    local filename="$2"
    echo "Downloading resource $filename"
    curl -fsSL -o "${RESOURCES_DIR}/${filename}" "$url"
}
