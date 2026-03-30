#!/bin/bash
set -e

ARCH_INPUT=${1:-generic}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
VCPKG_ROOT=${VCPKG_ROOT:-$PROJECT_ROOT/.vcpkg}
OUTPUT_DIR=${OUTPUT_DIR:-$PROJECT_ROOT/output}
VCPKG_BINARY_CACHE=${VCPKG_BINARY_CACHE:-/cache/vcpkg-binary-cache}

case $ARCH_INPUT in
    x64-linux|x64)    TRIPLET="x64-linux" ;;
    arm64-linux|arm64) TRIPLET="arm64-linux" ;;
    x64-mingw|mingw)  TRIPLET="x64-mingw" ;;
    x64-windows-msvc|msvc) TRIPLET="x64-windows-msvc" ;;
    *)
        echo "Unknown target: $ARCH_INPUT"
        echo "Supported: x64-linux, arm64-linux, x64-mingw, x64-windows-msvc"
        exit 1
        ;;
esac

echo "=== Building Recoil Engine Libraries ==="
echo "Triplet: $TRIPLET"
echo ""

VCPKG_COMMIT=$(cat "$SCRIPT_DIR/VCPKG_COMMIT")

if [ ! -d "$VCPKG_ROOT" ]; then
    git clone https://github.com/microsoft/vcpkg.git "$VCPKG_ROOT"
    git -C "$VCPKG_ROOT" checkout "$VCPKG_COMMIT"
    "$VCPKG_ROOT/bootstrap-vcpkg.sh"
fi

mkdir -p "$VCPKG_BINARY_CACHE"

# Each build uses its own install root so parallel builds don't conflict
# on vcpkg's shared internal state (installed/vcpkg/, installed/<host-triplet>/).
INSTALL_ROOT=$(mktemp -d)
trap "rm -rf '$INSTALL_ROOT'" EXIT

"$VCPKG_ROOT/vcpkg" install \
    --triplet="$TRIPLET" \
    --overlay-triplets="$SCRIPT_DIR/triplets" \
    --overlay-ports="$SCRIPT_DIR/overlay-ports" \
    --x-manifest-root="$SCRIPT_DIR" \
    --x-install-root="$INSTALL_ROOT" \
    --binarysource="clear;files,$VCPKG_BINARY_CACHE,readwrite"

PREFIX="$INSTALL_ROOT/$TRIPLET"

SHARE_DIR="$PREFIX/share"
echo ""
echo "=== Fixing cmake configs ==="
cmake -DSHARE_DIR="$SHARE_DIR" -P "$SCRIPT_DIR/fix-cmake-configs.cmake"

echo ""
echo "=== Merging transitive deps into static archives ==="

merge_archive() {
    local target="$1"
    shift
    local deps=("$@")
    local mri_script="CREATE ${target}.new"
    mri_script="${mri_script}\nADDLIB ${target}"
    local merged=""
    for dep in "${deps[@]}"; do
        if [ -f "$dep" ]; then
            mri_script="${mri_script}\nADDLIB ${dep}"
            merged="${merged} $(basename "$dep")"
        fi
    done
    mri_script="${mri_script}\nSAVE\nEND"
    if [ -n "$merged" ]; then
        echo -e "$mri_script" | ar -M
        mv "${target}.new" "$target"
        ranlib "$target"
        echo "  $(basename "$target") <-${merged}"
    fi
}

# freetype/fontconfig/devil are dynamic on both Linux and MinGW now,
# so the freetype merge below only fires if a static build ever reappears.
if [ -f "$PREFIX/lib/libfreetype.a" ]; then
    merge_archive "$PREFIX/lib/libfreetype.a" \
        "$PREFIX/lib/libbrotlidec.a" \
        "$PREFIX/lib/libbrotlicommon.a" \
        "$PREFIX/lib/libbz2.a"
fi

if [ -f "$PREFIX/lib/libtiff.a" ]; then
    merge_archive "$PREFIX/lib/libtiff.a" \
        "$PREFIX/lib/liblzma.a"
fi

# Copy only the target triplet output to the final location
mkdir -p "$OUTPUT_DIR/installed"
rm -rf "$OUTPUT_DIR/installed/$TRIPLET"
cp -a "$PREFIX" "$OUTPUT_DIR/installed/$TRIPLET"

echo ""
echo "=== Build complete ==="
echo "Installed to: $OUTPUT_DIR/installed/$TRIPLET"
