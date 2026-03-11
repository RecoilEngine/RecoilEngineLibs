vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO zlib-ng/minizip-ng
    REF 4.1.0
    SHA512 0
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

# Handle copyright
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
