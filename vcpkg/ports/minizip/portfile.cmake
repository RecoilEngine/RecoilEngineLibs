vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO zlib-ng/minizip-ng
    REF 4.1.0
    SHA512 9ea5dde14acd2f7d1efd0e38b11017b679d3aaabac61552f9c5f4c7f45f2563543e0fbb2d74429c6b1b9c37d8728ebc4f1cf0efad5f71807c11bb8a2a681a556
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DMZ_COMPAT=ON
        -DMZ_COMPAT_VERSION=110
        -DMZ_LIBBSD=OFF
        -DMZ_PKCRYPT=OFF
        -DMZ_OPENSSL=OFF
        -DMZ_SIGNING=OFF
        -DMZ_WZAES=OFF
        -DMZ_BZIP2=OFF
        -DMZ_ZSTD=OFF
        -DBUILD_SHARED_LIBS=OFF
        -DMZ_BUILD_TESTS=OFF
        -DMZ_BUILD_UNIT_TESTS=OFF
        -DMZ_BUILD_FUZZ_TESTS=OFF
        -DMZ_BUILD_EXAMPLES=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/minizip)
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

# minizip-ng discovers zlib/lzma via pkg-config and bakes bare library names
# into INTERFACE_LINK_LIBRARIES.  Replace with cmake imported targets so the
# config works outside the build container.  The find_dependency() calls in
# minizip-config.cmake already create the required targets.
set(_targets_file "${CURRENT_PACKAGES_DIR}/share/${PORT}/minizip.cmake")
if(EXISTS "${_targets_file}")
    file(READ "${_targets_file}" _contents)
    string(REGEX REPLACE
        [=[INTERFACE_LINK_LIBRARIES "[^"]*"]=]
        [=[INTERFACE_LINK_LIBRARIES "ZLIB::ZLIB;LibLZMA::LibLZMA"]=]
        _contents "${_contents}")
    file(WRITE "${_targets_file}" "${_contents}")
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
