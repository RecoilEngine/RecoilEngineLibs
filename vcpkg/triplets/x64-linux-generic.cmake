set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)

# System-provided on Linux — build dynamic so other ports can compile
# against the headers, but the engine links the distro's own .so at runtime.
if(PORT MATCHES "^(freetype|fontconfig|sdl2)$")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

if(PORT STREQUAL "openal-soft")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
    # GCC 13 + old binutils 2.34: R_X86_64_PC32 against protected symbol fails with ld.bfd
    set(VCPKG_LINKER_FLAGS "-fuse-ld=gold")
endif()

set(VCPKG_C_FLAGS "-mtune=generic -march=x86-64 -mno-sse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -mno-popcnt -mno-avx -mno-avx2 -mno-clflushopt")
set(VCPKG_CXX_FLAGS "-mtune=generic -march=x86-64 -mno-sse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -mno-popcnt -mno-avx -mno-avx2 -mno-clflushopt")

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
