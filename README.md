# RecoilEngineLibs

Pre-built static libraries for the [Recoil engine](https://github.com/RecoilEngine). Built with [vcpkg](https://github.com/microsoft/vcpkg).

## Using pre-built releases

Download a release tarball from the [Releases page](https://github.com/RecoilEngine/RecoilEngineLibs/releases) and point CMake at it:

```bash
tar -xzf recoil-libs-x64-linux-generic.tar.gz -C /opt/recoil-libs
cmake -DCMAKE_PREFIX_PATH=/opt/recoil-libs ...
```

Available triplets per release:

| Tarball | Target |
|---|---|
| `recoil-libs-x64-linux-generic.tar.gz` | Linux x86-64, SSE2 baseline, glibc 2.31+ |
| `recoil-libs-arm64-linux.tar.gz` | Linux AArch64 (Cortex-A72 tuning) |
| `recoil-libs-x64-mingw-static.tar.gz` | Windows x86-64 via MinGW (GCC, static CRT) |

---

## Building locally

The build is driven by `vcpkg/build.sh` and optionally wrapped in Docker. Both paths produce the same output under `output/installed/<triplet>/`.

### Prerequisites (all paths)

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

# AArch64 cross-compile (requires gcc-aarch64-linux-gnu)
sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu
./vcpkg/build.sh arm64

# MinGW cross-compile (requires mingw-w64)
sudo apt-get install -y mingw-w64
./vcpkg/build.sh mingw-static
```

Output lands in `output/installed/<triplet>/`.

### Without Docker (native Windows with MinGW)

1. Install [MSYS2](https://www.msys2.org/) and open an **MSYS2 MinGW 64-bit** shell.
2. Install build tools:
   ```bash
   pacman -S --needed base-devel mingw-w64-x86_64-toolchain mingw-w64-x86_64-cmake git
   ```
3. Clone this repo and run the build script (Git Bash or MSYS2 bash):
   ```bash
   ./vcpkg/build.sh mingw-static
   ```
   vcpkg is bootstrapped automatically if `$VCPKG_ROOT` is not set.

> The `x64-mingw-static` triplet targets Windows 7+ (`_WIN32_WINNT=0x0601`), static CRT, POSIX threading model (required for `std::thread`/`std::mutex`).

### With Docker

Build all three targets using the Docker wrapper:

```bash
./docker/build.sh
```

Or build a single target manually:

```bash
docker build -t recoil-libs-base:latest -f docker/base.Dockerfile .
docker build --build-arg BASE_IMAGE=recoil-libs-base:latest \
             -t recoil-libs-linux-amd64:latest \
             -f docker/linux-amd64.Dockerfile .
docker run --rm \
    -v "$(pwd)/output:/build/spring-static-libs/output" \
    recoil-libs-linux-amd64:latest
```

---

## Windows / MSVC (not yet supported)

The current setup cross-compiles Windows targets from Linux using MinGW. Native MSVC builds are not yet automated but are straightforward to add:

1. Add a vcpkg triplet `vcpkg/triplets/x64-windows-static.cmake` (or use vcpkg's built-in `x64-windows-static`).
2. Add a GitHub Actions job on `windows-latest` — no Docker needed, just `actions/checkout` + vcpkg.
3. The `vcpkg.json` manifest is fully compatible with MSVC; no port changes are required.

The MinGW release tarball is usable with MSVC projects via `CMAKE_PREFIX_PATH` as long as you do not mix the CRT (link against the MinGW-built `.lib` files only from a MinGW/Clang toolchain, not MSVC).

---

## Repository layout

```
vcpkg/
  vcpkg.json          # manifest — library list and version baseline
  build.sh            # build entrypoint (works with or without Docker)
  ports/              # overlay ports (local patches/overrides)
  triplets/           # custom vcpkg triplets
    x64-linux-generic.cmake   # x86-64, SSE2 baseline, hard-disabled SSE3+
    arm64-linux.cmake         # AArch64 cross-compile
    x64-mingw-static.cmake    # Windows MinGW static
    x64-mingw-dynamic.cmake   # Windows MinGW dynamic
docker/
  base.Dockerfile     # Ubuntu 20.04 + build tools + vcpkg bootstrap
  linux-amd64.Dockerfile
  linux-arm64.Dockerfile
  mingw.Dockerfile
  build.sh            # builds all Docker images and runs all three targets
.github/workflows/
  build.yml           # CI: build matrix + release job on tag push
```
