#!/bin/bash
set -e

ARCH_INPUT=${1:-generic}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VCPKG_ROOT=${VCPKG_ROOT:-$PROJECT_ROOT/.vcpkg}
OUTPUT_DIR=${OUTPUT_DIR:-$PROJECT_ROOT/output}
VCPKG_BINARY_CACHE=${VCPKG_BINARY_CACHE:-/cache/vcpkg-binary-cache}

case $ARCH_INPUT in
    generic)                      TRIPLET="x64-linux-generic" ;;
    arm64)                        TRIPLET="arm64-linux" ;;
    mingw-static|x64-mingw-static) TRIPLET="x64-mingw-static" ;;
    *)
        echo "Unknown target: $ARCH_INPUT"
        echo "Supported: generic, arm64, mingw-static"
        exit 1
        ;;
esac

echo "=== Building Recoil Engine Libraries ==="
echo "Triplet: $TRIPLET"
echo ""

if [ ! -d "$VCPKG_ROOT" ]; then
    git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
    "$VCPKG_ROOT/bootstrap-vcpkg.sh"
fi

mkdir -p "$VCPKG_BINARY_CACHE"

"$VCPKG_ROOT/vcpkg" install \
    --triplet="$TRIPLET" \
    --overlay-triplets="$SCRIPT_DIR/triplets" \
    --x-manifest-root="$SCRIPT_DIR" \
    --x-install-root="$OUTPUT_DIR/installed" \
    --binarysource="clear;files,$VCPKG_BINARY_CACHE,readwrite"

SHARE_DIR="$OUTPUT_DIR/installed/$TRIPLET/share"
echo ""
echo "=== Fixing cmake configs ==="
cmake -DSHARE_DIR="$SHARE_DIR" -P "$SCRIPT_DIR/fix-cmake-configs.cmake"

echo ""
echo "=== Build complete ==="
echo "Installed to: $OUTPUT_DIR/installed/$TRIPLET"
