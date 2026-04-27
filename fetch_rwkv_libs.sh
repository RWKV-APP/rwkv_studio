#!/bin/sh
# Usage: ./fetch_rwkv_libs.sh [macos|linux|windows|all]
# Without argument: fetch all platforms
set -e

PLATFORM=${1:-all}
BASE_URL="https://github.com/dengzii/rwkv_libs/releases/download/latest"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

download() {
    echo "  Downloading $1"
    curl -fSL "$1" -o "$2"
}

fetch_macos() {
    echo "Fetching macOS libs..."
    download "$BASE_URL/librwkv_mobile-dev-latest-macos.zip" "$TMP_DIR/macos.zip"
    unzip -qo "$TMP_DIR/macos.zip" -d "$TMP_DIR/macos"
    cp -r "$TMP_DIR/macos/"* macos/
}

fetch_linux() {
    echo "Fetching Linux libs..."
    download "$BASE_URL/librwkv_mobile-dev-latest-linux-x86_64.zip" "$TMP_DIR/linux-x86_64.zip"
    unzip -qo "$TMP_DIR/linux-x86_64.zip" -d "$TMP_DIR/linux-x86_64"
    cp -r "$TMP_DIR/linux-x86_64/"* linux/

    download "$BASE_URL/librwkv_mobile-dev-latest-linux-aarch64.zip" "$TMP_DIR/linux-aarch64.zip"
    unzip -qo "$TMP_DIR/linux-aarch64.zip" -d "$TMP_DIR/linux-aarch64"
    cp -r "$TMP_DIR/linux-aarch64/"* linux/
}

fetch_windows() {
    echo "Fetching Windows libs..."
    download "$BASE_URL/librwkv_mobile-dev-latest-windows-x64.zip" "$TMP_DIR/windows-x64.zip"
    unzip -qo "$TMP_DIR/windows-x64.zip" -d "$TMP_DIR/windows-x64"
    if [ -d "$TMP_DIR/windows-x64/Release" ]; then
        cp -r "$TMP_DIR/windows-x64/Release/"* windows/
    else
        cp -r "$TMP_DIR/windows-x64/"* windows/
    fi
}

case "$PLATFORM" in
    macos)   fetch_macos ;;
    linux)   fetch_linux ;;
    windows) fetch_windows ;;
    all)
        fetch_macos
        fetch_linux
        fetch_windows
        ;;
    *)
        echo "Unknown platform: $PLATFORM"
        echo "Usage: $0 [macos|linux|windows|all]"
        exit 1
        ;;
esac

echo "Done."
