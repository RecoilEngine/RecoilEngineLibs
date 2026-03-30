# RecoilEngineLibs

Pre-built libraries for the [Recoil engine](https://github.com/RecoilEngine). Built with [vcpkg](https://github.com/microsoft/vcpkg).

## Libraries

| Library | linux (static) | linux (shared) | mingw (static) | mingw (shared) | msvc (shared) | Notes |
|---|---|---|---|---|---|---|
| zlib | ✓ | | ✓ | | ✓ | |
| libpng | ✓ | | ✓ | | ✓ | |
| giflib | ✓ | | ✓ | | ✓ | |
| libjpeg-turbo | ✓ | | ✓ | | ✓ | |
| tiff | ✓ | | ✓ | | ✓ | liblzma merged into static archive (linux/mingw) |
| DevIL (IL + ILU) | ✓ | | | ✓ | ✓ | ILUT excluded |
| libunwind | ✓ | | | | | |
| openssl | ✓ | | ✓ | | ✓ | |
| nghttp2 | ✓ | | ✓ | | ✓ | |
| libpsl | ✓ | | ✓ | | ✓ | |
| curl | ✓ | | ✓ | | ✓ | |
| libogg | ✓ | | ✓ | | ✓ | |
| libvorbis | ✓ | | ✓ | | ✓ | |
| libuuid | ✓ | | | | | |
| liblzma | ✓ | | ✓ | | ✓ | |
| minizip | ✓ | | ✓ | | ✓ | |
| freetype | ✓ | | | ✓ | ✓ | |
| fontconfig | ✓ | | | ✓ | ✓ | |
| sdl2 | | ✓ | ✓ | | ✓ | |
| openal-soft | | ✓ | | ✓ | ✓ | OpenAL32.dll / libopenal.so |

## Using pre-built releases

Download a release tarball from the [Releases page](https://github.com/RecoilEngine/RecoilEngineLibs/releases) and extract it:

```bash
tar -xzf recoil-libs-x64-linux-generic.tar.gz -C /opt/recoil-libs
```

In your CMake project, include the setup file before calling `find_package`:

```cmake
include(/opt/recoil-libs/recoil-libs.cmake)
```

This adds the install prefix to `CMAKE_PREFIX_PATH`, enables `CMAKE_FIND_PACKAGE_PREFER_CONFIG`, and sets up `CMAKE_MODULE_PATH` so that the bundled CMake config files (with correct transitive dependency declarations) take priority over CMake's built-in Find modules.

Available triplets per release:

| Tarball | Target |
|---|---|
| `recoil-libs-x64-linux-generic.tar.gz` | Linux x86-64, SSE2 baseline, glibc 2.31+ |
| `recoil-libs-arm64-linux.tar.gz` | Linux AArch64 (Cortex-A72 tuning) |
| `recoil-libs-x64-mingw-static.tar.gz` | Windows x86-64 via MinGW (GCC, static CRT) |
| `recoil-libs-x64-windows-msvc.tar.gz` | Windows x86-64 via MSVC (dynamic CRT, DLLs) |

---

## Building locally

The build is driven by `vcpkg/build.sh` and optionally wrapped in Docker. Both paths produce the same output under `output/installed/<triplet>/`.

### Prerequisites

- **Git**
- **CMake 3.20+**
- **vcpkg** — cloned and bootstrapped automatically by `build.sh` if `$VCPKG_ROOT` is not set

### Without Docker (native Linux)

Install system dependencies (Ubuntu/Debian):

```bash
sudo apt-get install -y \
    build-essential cmake git curl wget \
    pkg-config autoconf-archive automake libtool \
    unzip zip python3
```

> **Note:** vcpkg host tools require **autoconf 2.70+**. Ubuntu 20.04 ships 2.69 — build from source:
> ```bash
> curl -sSL https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz | tar -xz
> cd autoconf-2.71 && ./configure --prefix=/usr/local && make -j$(nproc) && sudo make install
> ```
> Ubuntu 22.04+ ships a recent enough autoconf and can skip this step.

Build:

```bash
# x86-64 (SSE2 baseline)
./vcpkg/build.sh generic

# AArch64 (native, on an ARM64 host)
./vcpkg/build.sh arm64

# MinGW cross-compile (requires mingw-w64)
sudo apt-get install -y mingw-w64
./vcpkg/build.sh mingw-static
```

Output lands in `output/installed/<triplet>/`.

### With Docker

Build Docker images and run all targets:

```bash
./docker/build.sh
```

Or build a single target manually:

```bash
# Linux amd64
docker build -t recoil-libs-base:latest -f docker/base.Dockerfile .
docker build --build-arg BASE_IMAGE=recoil-libs-base:latest \
             -t recoil-libs-linux-amd64:latest \
             -f docker/linux-amd64.Dockerfile .
docker run --rm \
    -v "$(pwd)/output:/build/recoil-libs/output" \
    -v "$(pwd)/vcpkg-binary-cache:/cache/vcpkg-binary-cache" \
    recoil-libs-linux-amd64:latest

# MinGW
docker build -t recoil-libs-mingw:latest -f docker/mingw.Dockerfile .
docker run --rm \
    -v "$(pwd)/output:/build/recoil-libs/output" \
    -v "$(pwd)/vcpkg-binary-cache:/cache/vcpkg-binary-cache" \
    recoil-libs-mingw:latest
```

Multiple targets can run in parallel — each build uses an isolated temporary install root.

---

## Repository layout

```
vcpkg/
  vcpkg.json              # manifest — library list and version baseline
  VCPKG_COMMIT            # pinned vcpkg commit (matches builtin-baseline)
  build.sh                # build entrypoint (works with or without Docker)
  fix-cmake-configs.cmake # post-install cmake config fixups
  overlay-ports/          # overlay ports (local patches, e.g. DevIL)
  triplets/               # custom vcpkg triplets
    x64-linux-generic.cmake
    arm64-linux.cmake
    x64-mingw-static.cmake
    x64-windows-msvc.cmake
docker/
  base.Dockerfile         # Ubuntu 20.04 + build tools + vcpkg bootstrap
  linux-amd64.Dockerfile
  linux-arm64.Dockerfile
  mingw.Dockerfile        # Ubuntu 24.04 + MinGW GCC 13
  build.sh                # builds Docker images
.github/workflows/
  build.yml               # CI: build matrix + release on tag push
```
