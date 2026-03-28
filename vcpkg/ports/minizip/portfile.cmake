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
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
