#!/bin/bash
# Build Docker images for RecoilEngineLibs.
# Usage: ./docker/build.sh [base|linux-amd64|linux-arm64|mingw|all]
set -e

TARGET=${1:-all}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

build_base() {
    echo "=== Building base image ==="
    docker build -t recoil-libs-base:latest \
        -f "$SCRIPT_DIR/base.Dockerfile" "$PROJECT_ROOT"
}

build_linux_amd64() {
    echo "=== Building linux-amd64 image ==="
    docker build -t recoil-libs-linux-amd64:latest \
        -f "$SCRIPT_DIR/linux-amd64.Dockerfile" "$PROJECT_ROOT"
}

build_linux_arm64() {
    echo "=== Building linux-arm64 image ==="
    docker build -t recoil-libs-linux-arm64:latest \
        -f "$SCRIPT_DIR/linux-arm64.Dockerfile" "$PROJECT_ROOT"
}

build_mingw() {
    echo "=== Building mingw image ==="
    docker build -t recoil-libs-mingw:latest \
        -f "$SCRIPT_DIR/mingw.Dockerfile" "$PROJECT_ROOT"
}

case $TARGET in
    base)         build_base ;;
    linux-amd64)  build_base && build_linux_amd64 ;;
    linux-arm64)  build_base && build_linux_arm64 ;;
    mingw)        build_mingw ;;
    all)          build_base && build_linux_amd64 && build_linux_arm64 && build_mingw ;;
    *)
        echo "Usage: $0 [base|linux-amd64|linux-arm64|mingw|all]"
        exit 1
        ;;
esac

echo ""
echo "Done. Run a build with:"
echo "  docker run --rm -v \$PWD/output:/build/output recoil-libs-<target>:latest"
