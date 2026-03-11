vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO curl/curl
    REF curl-8_15_0
    SHA512 0
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DCMAKE_DISABLE_FIND_PACKAGE_Perl=ON
        -DENABLE_MANUAL=OFF
        -DENABLE_VERBOSE=OFF
        -DCURL_ENABLE_SSL=ON
        -DENABLE_HTTP=ON
        -DENABLE_HTTPS=ON
        -DENABLE_FILE=ON
        -DENABLE_LDAP=OFF
        -DENABLE_RTSP=OFF
        -DENABLE_DICT=OFF
        -DENABLE_TELNET=OFF
        -DENABLE_TFTP=OFF
        -DENABLE_POP3=OFF
        -DENABLE_IMAP=OFF
        -DENABLE_SMTP=OFF
        -DENABLE_GOPHER=OFF
        -DENABLE_MQTT=OFF
        -DUSE_NGHTTP2=ON
        -DCURL_USE_OPENSSL=ON
        -DCURL_USE_LIBPSL=ON
        -DBUILD_SHARED_LIBS=OFF
        -DCURL_DISABLE_TESTS=ON
)

vcpkg_cmake_install()
vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Handle copyright
file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
