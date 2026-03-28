set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE static)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)

set(VCPKG_C_FLAGS "-mtune=generic -march=x86-64 -mno-sse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -mno-popcnt -mno-avx -mno-avx2 -mno-clflushopt")
set(VCPKG_CXX_FLAGS "-mtune=generic -march=x86-64 -mno-sse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -mno-popcnt -mno-avx -mno-avx2 -mno-clflushopt")
set(VCPKG_LINKER_FLAGS "")

set(VCPKG_CMAKE_CONFIGURE_OPTIONS
    -DCMAKE_CXX_STANDARD=17
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
