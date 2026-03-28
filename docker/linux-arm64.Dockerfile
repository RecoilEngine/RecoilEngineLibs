ARG BASE_IMAGE=recoil-libs-base:latest
FROM ${BASE_IMAGE}

# Install aarch64 cross-compilation toolchain.
# gcc-aarch64-linux-gnu provides the unversioned symlinks vcpkg's linux.cmake expects.
# gcc-10-aarch64-linux-gnu is the highest version available on Ubuntu 20.04.
RUN apt-get update && apt-get install -y \
        gcc-aarch64-linux-gnu \
        g++-aarch64-linux-gnu \
        gcc-10-aarch64-linux-gnu \
        g++-10-aarch64-linux-gnu \
    && ln -sf /usr/bin/aarch64-linux-gnu-gcc-10 /usr/bin/aarch64-linux-gnu-gcc \
    && ln -sf /usr/bin/aarch64-linux-gnu-g++-10 /usr/bin/aarch64-linux-gnu-g++ \
    && rm -rf /var/lib/apt/lists/*

COPY vcpkg/ /build/recoil-libs/vcpkg/
WORKDIR /build/recoil-libs
RUN chmod +x vcpkg/build.sh

CMD ["./vcpkg/build.sh", "arm64"]
