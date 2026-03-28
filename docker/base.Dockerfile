FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
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
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 18.04 ships cmake 3.10 — vcpkg needs >= 3.20.
RUN CMAKE_VERSION=3.31.6 && \
    ARCH=$(uname -m) && \
    wget -q "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-${ARCH}.tar.gz" && \
    tar -xzf "cmake-${CMAKE_VERSION}-linux-${ARCH}.tar.gz" --strip-components=1 -C /usr/local && \
    rm "cmake-${CMAKE_VERSION}-linux-${ARCH}.tar.gz"

# Install autoconf 2.71 from source.
# Ubuntu 18.04 ships autoconf 2.69, but gperf 3.3 (a vcpkg host tool) requires >= 2.70.
RUN curl -sSL https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz \
      | tar -xz \
    && cd autoconf-2.71 \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) \
    && make install \
    && cd .. && rm -rf autoconf-2.71

WORKDIR /build

# Create cache directory for vcpkg binary caching.
# Mount a volume here to persist cache across runs:
#   docker run -v /host/cache:/cache ...
RUN mkdir -p /cache/vcpkg-binary-cache && chmod 777 /cache/vcpkg-binary-cache

# Clone and bootstrap vcpkg
RUN git clone https://github.com/microsoft/vcpkg.git /build/vcpkg && \
    /build/vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT=/build/vcpkg
ENV VCPKG_BINARY_CACHE=/cache/vcpkg-binary-cache
ENV PATH="${VCPKG_ROOT}:${PATH}"
