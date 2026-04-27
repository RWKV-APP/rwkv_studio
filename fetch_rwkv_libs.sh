#!/bin/sh
# Usage: ./fetch_rwkv_libs.sh [macos|linux|windows]
# Without argument: fetch all platforms

PLATFORM=${1:-all}
BASE_URL="https://github.com/dengzii/rwkv_libs/releases/download/latest"

download() {
    curl -fSL "$1" -o "$2"
}

fetch_macos() {
    echo "Fetching macOS libs..."
    mkdir -p tmp/macos
    download "$BASE_URL/librwkv_mobile-dev-latest-macos.zip" tmp/macos.zip
    unzip -q tmp/macos.zip -d tmp/macos
    cp -r tmp/macos/* macos/
}

fetch_linux() {
    echo "Fetching Linux libs..."
    mkdir -p tmp/linux
    download "$BASE_URL/librwkv_mobile-dev-latest-linux-x86_64.zip" tmp/linux.zip
    unzip -q tmp/linux.zip -d tmp/linux
    cp -r tmp/linux/* linux/
}

fetch_windows() {
    echo "Fetching Windows libs..."
    mkdir -p tmp/windows
    download "$BASE_URL/librwkv_mobile-dev-latest-windows-x64.zip" tmp/windows.zip
    unzip -q tmp/windows.zip -d tmp/windows
    if [ -d tmp/windows/Release ]; then
        cp -r tmp/windows/Release/* windows/
    else
        cp -r tmp/windows/* windows/
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
        echo "Usage: $0 [macos|linux|windows]"
        exit 1
        ;;
esac

rm -rf tmp
echo "Done."
