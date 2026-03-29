set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_BUILD_TYPE release)

if(PORT STREQUAL "openal-soft")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

set(VCPKG_C_FLAGS "-march=armv8-a+crc+crypto -mtune=cortex-a72")
set(VCPKG_CXX_FLAGS "-march=armv8-a+crc+crypto -mtune=cortex-a72")
set(VCPKG_LINKER_FLAGS "")

set(VCPKG_CMAKE_CONFIGURE_OPTIONS
    -DCMAKE_CXX_STANDARD=17
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
