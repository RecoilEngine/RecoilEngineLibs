# Post-install fixups for cmake config files.
#
# vcpkg's generated cmake configs assume consumption through vcpkg's own
# toolchain file.  When the libraries are consumed standalone (via
# CMAKE_PREFIX_PATH), several transitive dependency declarations are
# missing, causing undefined-symbol link errors.
#
# Usage:  cmake -DSHARE_DIR=<.../installed/<triplet>/share> -P fix-cmake-configs.cmake

if(NOT DEFINED SHARE_DIR)
    message(FATAL_ERROR "SHARE_DIR must be set (-DSHARE_DIR=...)")
endif()

# ---------------------------------------------------------------------------
# freetype
# ---------------------------------------------------------------------------
# freetype-config.cmake is a bare include() — no find_dependency() calls.
# freetype-targets.cmake references $<LINK_ONLY:ZLIB::ZLIB> (needs the
# target to exist) and hardcoded .a paths for bz2/brotli/png.

set(_file "${SHARE_DIR}/freetype/freetype-config.cmake")
if(EXISTS "${_file}")
    file(WRITE "${_file}" [=[include(CMakeFindDependencyMacro)
find_dependency(ZLIB)
find_dependency(BZip2)
find_dependency(PNG)
find_dependency(unofficial-brotli CONFIG)
include("${CMAKE_CURRENT_LIST_DIR}/freetype-targets.cmake")
]=])
    message(STATUS "Fixed freetype-config.cmake")
endif()

set(_file "${SHARE_DIR}/freetype/freetype-targets.cmake")
if(EXISTS "${_file}")
    file(READ "${_file}" _contents)
    string(REGEX REPLACE
        [=[INTERFACE_LINK_LIBRARIES "[^"]*VCPKG_IMPORT_PREFIX[^"]*"]=]
        [=[INTERFACE_LINK_LIBRARIES "\\$<LINK_ONLY:ZLIB::ZLIB>;\\$<LINK_ONLY:BZip2::BZip2>;\\$<LINK_ONLY:PNG::PNG>;\\$<LINK_ONLY:m>;\\$<LINK_ONLY:unofficial::brotli::brotlidec>"]=]
        _contents "${_contents}")
    file(WRITE "${_file}" "${_contents}")
    message(STATUS "Fixed freetype-targets.cmake")
endif()

# ---------------------------------------------------------------------------
# tiff
# ---------------------------------------------------------------------------
# tiff has no cmake config file — only a vcpkg-cmake-wrapper.cmake that
# requires vcpkg's toolchain.  Create a proper TIFFConfig.cmake so
# find_package(TIFF CONFIG) works and declares liblzma/zlib/jpeg deps.

set(_tiff_dir "${SHARE_DIR}/tiff")
if(IS_DIRECTORY "${_tiff_dir}" AND NOT EXISTS "${_tiff_dir}/TIFFConfig.cmake")
    file(WRITE "${_tiff_dir}/TIFFConfig.cmake" [=[get_filename_component(_TIFF_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../" ABSOLUTE)

include(CMakeFindDependencyMacro)
find_dependency(ZLIB)
find_dependency(LibLZMA)
find_dependency(JPEG)

if(NOT TARGET TIFF::TIFF)
    find_library(_TIFF_LIBRARY NAMES tiff PATHS "${_TIFF_PREFIX}/lib" NO_DEFAULT_PATH)
    if(NOT _TIFF_LIBRARY)
        set(TIFF_FOUND FALSE)
        return()
    endif()

    add_library(TIFF::TIFF STATIC IMPORTED)
    set_target_properties(TIFF::TIFF PROPERTIES
        IMPORTED_LOCATION "${_TIFF_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${_TIFF_PREFIX}/include"
        INTERFACE_LINK_LIBRARIES "ZLIB::ZLIB;LibLZMA::LibLZMA;JPEG::JPEG"
    )
    if(UNIX)
        set_property(TARGET TIFF::TIFF APPEND PROPERTY INTERFACE_LINK_LIBRARIES m)
    endif()
    unset(_TIFF_LIBRARY CACHE)
endif()

set(TIFF_FOUND TRUE)
set(TIFF_INCLUDE_DIRS "${_TIFF_PREFIX}/include")
set(TIFF_LIBRARIES TIFF::TIFF)
unset(_TIFF_PREFIX)
]=])
    message(STATUS "Created TIFFConfig.cmake")
endif()
