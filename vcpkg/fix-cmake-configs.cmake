# Post-install fixups for cmake config files.
#
# vcpkg's generated cmake configs reference vcpkg-internal variables and
# bake in absolute build-time paths that don't resolve when the libraries
# are consumed standalone (via CMAKE_PREFIX_PATH without vcpkg toolchain).
# This script rewrites the problematic configs to use proper cmake imported
# targets and find_dependency() calls.
#
# Usage:  cmake -DSHARE_DIR=<.../installed/<triplet>/share> -P fix-cmake-configs.cmake

if(NOT DEFINED SHARE_DIR)
    message(FATAL_ERROR "SHARE_DIR must be set (-DSHARE_DIR=...)")
endif()

# ---------------------------------------------------------------------------
# freetype
# ---------------------------------------------------------------------------
# freetype-config.cmake is a bare include() with no find_dependency() calls.
# freetype-targets.cmake has $<LINK_ONLY:ZLIB::ZLIB> (needs the target to
# exist) and hardcoded .a paths via VCPKG_IMPORT_PREFIX for bz2/brotli/png.

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
# openal-soft
# ---------------------------------------------------------------------------
# The vcpkg port de-vendors fmt (devendor-fmt.diff), so libopenal.a contains
# weak fmt symbols from template instantiations while the cmake config also
# declares find_dependency(fmt) which pulls in libfmt.a — causing duplicate
# symbol errors.  Remove the fmt dependency; the weak symbols in libopenal
# satisfy all internal references.
# For dynamic builds (.so / .dll) fmt is a private dep and shouldn't be
# exposed at all.

set(_file "${SHARE_DIR}/openal-soft/OpenALConfig.cmake")
if(EXISTS "${_file}")
    file(READ "${_file}" _contents)
    string(REPLACE "find_dependency(fmt CONFIG)\n" "" _contents "${_contents}")
    string(REPLACE "find_dependency(fmt CONFIG)" "" _contents "${_contents}")
    file(WRITE "${_file}" "${_contents}")
    message(STATUS "Fixed OpenALConfig.cmake")
endif()

set(_file "${SHARE_DIR}/openal-soft/OpenALTargets.cmake")
if(EXISTS "${_file}")
    file(READ "${_file}" _contents)
    string(REPLACE [=[;\$<LINK_ONLY:fmt::fmt>]=] "" _contents "${_contents}")
    string(REPLACE [=[\$<LINK_ONLY:fmt::fmt>;]=] "" _contents "${_contents}")
    string(REPLACE [=[\$<LINK_ONLY:fmt::fmt>]=] "" _contents "${_contents}")
    file(WRITE "${_file}" "${_contents}")
    message(STATUS "Fixed OpenALTargets.cmake")
endif()
