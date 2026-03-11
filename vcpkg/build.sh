#!/bin/bash
set -e

# Configuration
ARCH_INPUT=${1:-generic}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VCPKG_ROOT=${VCPKG_ROOT:-$PROJECT_ROOT/.vcpkg}
OUTPUT_DIR=${OUTPUT_DIR:-$PROJECT_ROOT/output}

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
    *)
        echo "Unknown architecture: $ARCH_INPUT"
        echo "Supported architectures: generic, nehalem, arm64"
        exit 1
        ;;
esac

echo "=== Building Spring Static Libraries ==="
echo "Architecture: $ARCH_INPUT"
echo "Triplet: $TRIPLET"
echo "VCPKG_ROOT: $VCPKG_ROOT"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Ensure vcpkg is available
if [ ! -d "$VCPKG_ROOT" ]; then
    echo "Cloning vcpkg..."
    git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
    echo "Bootstrapping vcpkg..."
    "$VCPKG_ROOT/bootstrap-vcpkg.sh"
fi

# Copy custom triplets to vcpkg
echo "Installing custom triplets..."
mkdir -p "$VCPKG_ROOT/triplets/community"
cp "$SCRIPT_DIR/triplets/"*.cmake "$VCPKG_ROOT/triplets/community/"

# Build with vcpkg
echo "Running vcpkg install..."
"$VCPKG_ROOT/vcpkg" install \
    --triplet="$TRIPLET" \
    --overlay-ports="$SCRIPT_DIR/ports" \
    --x-manifest-root="$SCRIPT_DIR" \
    --x-install-root="$OUTPUT_DIR/installed"

# Copy final libraries to output
echo "Copying libraries to output directory..."
mkdir -p "$OUTPUT_DIR/lib"
mkdir -p "$OUTPUT_DIR/include"
cp -r "$OUTPUT_DIR/installed/$TRIPLET/lib/"* "$OUTPUT_DIR/lib/" 2>/dev/null || true
cp -r "$OUTPUT_DIR/installed/$TRIPLET/include/"* "$OUTPUT_DIR/include/" 2>/dev/null || true

echo ""
echo "=== Build complete ==="
echo "Libraries installed in: $OUTPUT_DIR"
echo "  - Libraries: $OUTPUT_DIR/lib"
echo "  - Headers: $OUTPUT_DIR/include"
