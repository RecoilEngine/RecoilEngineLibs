ARG BASE_IMAGE=recoil-libs-base:latest
FROM ${BASE_IMAGE}

# Install GCC 13 from ubuntu-toolchain-r/test PPA
RUN add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y \
        gcc-13 \
        g++-13 \
        ninja-build \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libx11-dev \
        libxext-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxi-dev \
        libxft-dev \
        libasound2-dev \
        libpulse-dev \
        libdrm-dev \
        libgbm-dev \
        libwayland-dev \
        libxkbcommon-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 130 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 130 \
    && rm -rf /var/lib/apt/lists/*

COPY vcpkg/ /build/recoil-libs/vcpkg/
WORKDIR /build/recoil-libs
RUN chmod +x vcpkg/build.sh

CMD ["./vcpkg/build.sh", "generic"]
