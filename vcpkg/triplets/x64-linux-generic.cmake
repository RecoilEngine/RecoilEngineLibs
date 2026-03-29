set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)

set(VCPKG_C_FLAGS "-mtune=generic -march=x86-64 -mno-sse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -mno-popcnt -mno-avx -mno-avx2 -mno-clflushopt")
set(VCPKG_CXX_FLAGS "-mtune=generic -march=x86-64 -mno-sse3 -mno-ssse3 -mno-sse4.1 -mno-sse4.2 -mno-popcnt -mno-avx -mno-avx2 -mno-clflushopt")

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
