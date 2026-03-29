set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)

# System-provided on Linux — build dynamic so other ports can compile
# against the headers, but the engine links the distro's own .so at runtime.
if(PORT STREQUAL "openal-soft")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
    # GCC 13 + old binutils 2.34: protected-visibility relocations fail with ld.bfd
    set(VCPKG_LINKER_FLAGS "-fuse-ld=gold")
endif()

set(VCPKG_C_FLAGS "-march=armv8-a+crc+crypto -mtune=cortex-a72")
set(VCPKG_CXX_FLAGS "-march=armv8-a+crc+crypto -mtune=cortex-a72")

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
