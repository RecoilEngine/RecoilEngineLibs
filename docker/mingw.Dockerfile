# Self-contained image based on Ubuntu 24.04 for a newer MinGW GCC (13+).
# Ubuntu 20.04's mingw-w64 ships GCC 9.3 which lacks C++20 support
# needed by some dependencies (e.g. openal-soft requires <concepts>).
# Since this image cross-compiles for Windows, glibc version doesn't matter.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    pkg-config \
    autoconf-archive \
    automake \
    libtool \
    unzip \
    zip \
    python3 \
    ninja-build \
    mingw-w64 \
    mingw-w64-tools \
    && update-alternatives \
        --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix \
    && update-alternatives \
        --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN mkdir -p /cache/vcpkg-binary-cache && chmod 777 /cache/vcpkg-binary-cache

COPY vcpkg/VCPKG_COMMIT /tmp/vcpkg-commit
RUN git clone https://github.com/microsoft/vcpkg.git /build/vcpkg && \
    git -C /build/vcpkg checkout "$(cat /tmp/vcpkg-commit)" && \
    /build/vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT=/build/vcpkg
ENV VCPKG_BINARY_CACHE=/cache/vcpkg-binary-cache
ENV PATH="${VCPKG_ROOT}:${PATH}"

COPY vcpkg/ /build/recoil-libs/vcpkg/
WORKDIR /build/recoil-libs
RUN chmod +x vcpkg/build.sh

CMD ["./vcpkg/build.sh", "mingw-static"]
