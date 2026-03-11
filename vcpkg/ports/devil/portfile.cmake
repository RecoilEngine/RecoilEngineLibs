vcpkg_download_distfile(ARCHIVE
    URLS "https://downloads.sourceforge.net/project/openil/DevIL/1.8.0/DevIL-1.8.0.tar.gz"
    FILENAME "DevIL-1.8.0.tar.gz"
    SHA512 0
)

vcpkg_extract_source_archive(
    SOURCE_PATH "${ARCHIVE}"
    SOURCE_BASE DevIL-1.8.0
)

# Build IL component
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/DevIL/src-IL"
    OPTIONS
        -DBUILD_SHARED_LIBS=OFF
        -DCMAKE_CXX_FLAGS=-fpermissive
        -DCMAKE_C_FLAGS=-fpermissive
)

vcpkg_cmake_install()

# Build ILU component
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/DevIL/src-ILU"
    OPTIONS
        -DBUILD_SHARED_LIBS=OFF
)

vcpkg_cmake_install()

# Build ILUT component
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/DevIL/src-ILUT"
    OPTIONS
        -DBUILD_SHARED_LIBS=OFF
)

vcpkg_cmake_install()

vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

# Handle copyright
file(INSTALL "${SOURCE_PATH}/DevIL/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
