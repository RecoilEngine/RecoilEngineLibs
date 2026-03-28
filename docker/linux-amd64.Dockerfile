ARG BASE_IMAGE=recoil-libs-base:latest
FROM ${BASE_IMAGE}

# Install GCC 13 from ubuntu-toolchain-r/test PPA
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update && \
    apt-get install -y \
        gcc-13 \
        g++-13 \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libx11-dev \
        libxext-dev \
        libxrandr-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxi-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 130 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 130 \
    && rm -rf /var/lib/apt/lists/*

COPY vcpkg/ /build/spring-static-libs/vcpkg/
WORKDIR /build/spring-static-libs
RUN chmod +x vcpkg/build.sh

CMD ["./vcpkg/build.sh", "generic"]
