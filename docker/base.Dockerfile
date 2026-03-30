FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    autoconf-archive \
    automake \
    libtool \
    unzip \
    zip \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    rm -rf /var/lib/apt/lists/*

# gperf (vcpkg host tool for fontconfig) requires autoconf >= 2.70;
# Ubuntu 20.04 ships 2.69.
RUN curl -sSL https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.gz | tar -xz \
    && cd autoconf-2.71 \
    && ./configure --prefix=/usr/local \
    && make -j$(nproc) \
    && make install \
    && cd .. && rm -rf autoconf-2.71

WORKDIR /build

RUN mkdir -p /cache/vcpkg-binary-cache && chmod 777 /cache/vcpkg-binary-cache

COPY vcpkg/VCPKG_COMMIT /tmp/vcpkg-commit
RUN git clone https://github.com/microsoft/vcpkg.git /build/vcpkg && \
    git -C /build/vcpkg checkout "$(cat /tmp/vcpkg-commit)" && \
    /build/vcpkg/bootstrap-vcpkg.sh

ENV VCPKG_ROOT=/build/vcpkg
ENV VCPKG_BINARY_CACHE=/cache/vcpkg-binary-cache
ENV PATH="${VCPKG_ROOT}:${PATH}"
