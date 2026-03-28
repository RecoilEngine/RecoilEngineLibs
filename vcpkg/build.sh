#!/bin/bash
set -e

# Configuration
ARCH_INPUT=${1:-generic}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VCPKG_ROOT=${VCPKG_ROOT:-$PROJECT_ROOT/.vcpkg}
OUTPUT_DIR=${OUTPUT_DIR:-$PROJECT_ROOT/output}

# Binary cache configuration for vcpkg
# Set VCPKG_BINARY_CACHE to enable binary caching across container runs
# Example: docker run -v ~/.cache/vcpkg:/cache ...
VCPKG_BINARY_CACHE=${VCPKG_BINARY_CACHE:-/cache/vcpkg-binary-cache}

# Map architecture input to triplet
case $ARCH_INPUT in
    generic)
        TRIPLET="x64-linux-generic"
        ;;
    nehalem)
        TRIPLET="x64-linux-nehalem"
        ;;
    arm64)
        TRIPLET="arm64-linux"
        ;;
    mingw-static|x64-mingw-static)
        TRIPLET="x64-mingw-static"
        ;;
    mingw-dynamic|x64-mingw-dynamic)
        TRIPLET="x64-mingw-dynamic"
        ;;
    *)
        echo "Unknown architecture: $ARCH_INPUT"
        echo "Supported architectures: generic, nehalem, arm64, mingw-static, mingw-dynamic"
        exit 1
        ;;
esac

echo "=== Building Recoil Engine Libraries ==="
echo "Architecture: $ARCH_INPUT"
echo "Triplet: $TRIPLET"
echo "VCPKG_ROOT: $VCPKG_ROOT"
echo "Output directory: $OUTPUT_DIR"
echo "Binary cache: $VCPKG_BINARY_CACHE"
echo ""

# Ensure vcpkg is available
if [ ! -d "$VCPKG_ROOT" ]; then
    echo "Cloning vcpkg..."
    git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
    echo "Bootstrapping vcpkg..."
    "$VCPKG_ROOT/bootstrap-vcpkg.sh"
fi

# Copy custom triplets and toolchains to vcpkg
echo "Installing custom triplets..."
mkdir -p "$VCPKG_ROOT/triplets/community"
cp "$SCRIPT_DIR/triplets/"*.cmake "$VCPKG_ROOT/triplets/community/"
if ls "$SCRIPT_DIR/toolchains/"*.cmake &>/dev/null; then
    cp "$SCRIPT_DIR/toolchains/"*.cmake "$VCPKG_ROOT/scripts/toolchains/"
fi

# Ensure binary cache directory exists
if [ ! -d "$VCPKG_BINARY_CACHE" ]; then
    echo "Creating binary cache directory: $VCPKG_BINARY_CACHE"
    mkdir -p "$VCPKG_BINARY_CACHE"
fi

# Build with vcpkg using binary caching
# The binarysource flag enables caching compiled packages to avoid rebuilding
echo "Running vcpkg install with binary caching..."
"$VCPKG_ROOT/vcpkg" install \
    --triplet="$TRIPLET" \
    --overlay-triplets="$SCRIPT_DIR/triplets" \
    --overlay-ports="$SCRIPT_DIR/ports" \
    --x-manifest-root="$SCRIPT_DIR" \
    --x-install-root="$OUTPUT_DIR/installed" \
    --binarysource="clear;files,$VCPKG_BINARY_CACHE,readwrite"

# Copy final libraries to output
echo "Copying libraries to output directory..."
mkdir -p "$OUTPUT_DIR/lib"
mkdir -p "$OUTPUT_DIR/include"
mkdir -p "$OUTPUT_DIR/bin"
cp -r "$OUTPUT_DIR/installed/$TRIPLET/lib/"* "$OUTPUT_DIR/lib/" 2>/dev/null || true
cp -r "$OUTPUT_DIR/installed/$TRIPLET/include/"* "$OUTPUT_DIR/include/" 2>/dev/null || true
cp -r "$OUTPUT_DIR/installed/$TRIPLET/bin/"* "$OUTPUT_DIR/bin/" 2>/dev/null || true

echo ""
echo "=== Build complete ==="
echo "Libraries installed in: $OUTPUT_DIR"
echo "  - Libraries: $OUTPUT_DIR/lib"
echo "  - Headers: $OUTPUT_DIR/include"
