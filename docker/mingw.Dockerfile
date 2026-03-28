ARG BASE_IMAGE=recoil-libs-base:latest
FROM ${BASE_IMAGE}

# Install MinGW-w64 cross-compilation toolchain.
# Switch to POSIX threading model so std::thread / std::mutex are available.
RUN apt-get update && apt-get install -y \
        mingw-w64 \
        mingw-w64-tools \
    && update-alternatives \
        --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix \
    && update-alternatives \
        --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix \
    && rm -rf /var/lib/apt/lists/*

COPY vcpkg/ /build/spring-static-libs/vcpkg/
WORKDIR /build/spring-static-libs
RUN chmod +x vcpkg/build.sh

CMD ["./vcpkg/build.sh", "mingw-static"]
