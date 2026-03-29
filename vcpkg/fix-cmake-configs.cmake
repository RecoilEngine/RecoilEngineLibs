# Post-install fixups for cmake config files.
#
# vcpkg's generated cmake configs assume consumption through vcpkg's own
# toolchain file.  When the libraries are consumed standalone (via
# CMAKE_PREFIX_PATH), several transitive dependency declarations are
# missing, causing undefined-symbol link errors.
#
# This script also generates Find*.cmake wrapper modules so that
# find_package(Xxx) in MODULE mode picks up the fixed CONFIG files.
#
# Usage:  cmake -DSHARE_DIR=<.../installed/<triplet>/share> -P fix-cmake-configs.cmake

if(NOT DEFINED SHARE_DIR)
    message(FATAL_ERROR "SHARE_DIR must be set (-DSHARE_DIR=...)")
endif()

get_filename_component(_INSTALL_PREFIX "${SHARE_DIR}/.." ABSOLUTE)
set(_MODULES_DIR "${_INSTALL_PREFIX}/cmake/modules")
file(MAKE_DIRECTORY "${_MODULES_DIR}")

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
# requires vcpkg's toolchain.  Create a proper TIFFConfig.cmake.

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

# ---------------------------------------------------------------------------
# fontconfig
# ---------------------------------------------------------------------------
# fontconfig has no cmake config file — only a vcpkg-cmake-wrapper that
# uses vcpkg-internal _find_package().  Create FontconfigConfig.cmake
# with proper transitive deps (freetype, expat).

set(_fc_dir "${SHARE_DIR}/fontconfig")
if(IS_DIRECTORY "${_fc_dir}" AND NOT EXISTS "${_fc_dir}/FontconfigConfig.cmake")
    file(WRITE "${_fc_dir}/FontconfigConfig.cmake" [=[get_filename_component(_FC_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../" ABSOLUTE)

include(CMakeFindDependencyMacro)
find_dependency(Freetype CONFIG)
find_dependency(expat CONFIG)

if(NOT TARGET Fontconfig::Fontconfig)
    find_library(_FC_LIBRARY NAMES fontconfig PATHS "${_FC_PREFIX}/lib" NO_DEFAULT_PATH)
    if(NOT _FC_LIBRARY)
        set(Fontconfig_FOUND FALSE)
        return()
    endif()

    add_library(Fontconfig::Fontconfig STATIC IMPORTED)
    set_target_properties(Fontconfig::Fontconfig PROPERTIES
        IMPORTED_LOCATION "${_FC_LIBRARY}"
        INTERFACE_INCLUDE_DIRECTORIES "${_FC_PREFIX}/include"
        INTERFACE_LINK_LIBRARIES "Freetype::Freetype;expat::expat"
    )
    if(NOT WIN32)
        find_package(Iconv QUIET)
        if(Iconv_FOUND)
            set_property(TARGET Fontconfig::Fontconfig APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES Iconv::Iconv)
        endif()
    endif()
    unset(_FC_LIBRARY CACHE)
endif()

set(Fontconfig_FOUND TRUE)
set(FONTCONFIG_FOUND TRUE)
set(Fontconfig_INCLUDE_DIRS "${_FC_PREFIX}/include")
set(Fontconfig_LIBRARIES Fontconfig::Fontconfig)
unset(_FC_PREFIX)
]=])
    message(STATUS "Created FontconfigConfig.cmake")
endif()

# ---------------------------------------------------------------------------
# DevIL
# ---------------------------------------------------------------------------
# DevIL's header uses __declspec(dllimport) on _WIN32 by default.
# For static linking, consumers must define IL_STATIC_LIB.
# Create a cmake config that sets this automatically.

set(_devil_dir "${SHARE_DIR}/devil")
if(IS_DIRECTORY "${_devil_dir}" AND NOT EXISTS "${_devil_dir}/DevILConfig.cmake")
    file(WRITE "${_devil_dir}/DevILConfig.cmake" [=[get_filename_component(_DEVIL_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../" ABSOLUTE)

include(CMakeFindDependencyMacro)
find_dependency(ZLIB)
find_dependency(PNG)
find_dependency(JPEG)
find_dependency(TIFF CONFIG)

if(NOT TARGET DevIL::IL)
    # Detect whether we have a shared (.dll.a / .so) or static (.a / .lib) build
    find_library(_IL_IMPLIB NAMES DevIL.dll IL.dll PATHS "${_DEVIL_PREFIX}/lib" NO_DEFAULT_PATH)
    find_library(_IL_LIBRARY NAMES DevIL IL PATHS "${_DEVIL_PREFIX}/lib" NO_DEFAULT_PATH)
    find_library(_ILU_IMPLIB NAMES ILU.dll PATHS "${_DEVIL_PREFIX}/lib" NO_DEFAULT_PATH)
    find_library(_ILU_LIBRARY NAMES ILU PATHS "${_DEVIL_PREFIX}/lib" NO_DEFAULT_PATH)

    if(NOT _IL_LIBRARY AND NOT _IL_IMPLIB)
        set(DevIL_FOUND FALSE)
        return()
    endif()

    if(_IL_IMPLIB)
        # Shared (DLL) build — import lib + DLL
        add_library(DevIL::IL SHARED IMPORTED)
        set_target_properties(DevIL::IL PROPERTIES
            IMPORTED_IMPLIB "${_IL_IMPLIB}"
            INTERFACE_INCLUDE_DIRECTORIES "${_DEVIL_PREFIX}/include"
        )
    else()
        # Static build
        add_library(DevIL::IL STATIC IMPORTED)
        set_target_properties(DevIL::IL PROPERTIES
            IMPORTED_LOCATION "${_IL_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${_DEVIL_PREFIX}/include"
            INTERFACE_COMPILE_DEFINITIONS "IL_STATIC_LIB"
            INTERFACE_LINK_LIBRARIES "ZLIB::ZLIB;PNG::PNG;JPEG::JPEG;TIFF::TIFF"
        )
    endif()

    if(_ILU_IMPLIB)
        add_library(DevIL::ILU SHARED IMPORTED)
        set_target_properties(DevIL::ILU PROPERTIES
            IMPORTED_IMPLIB "${_ILU_IMPLIB}"
            INTERFACE_INCLUDE_DIRECTORIES "${_DEVIL_PREFIX}/include"
        )
    elseif(_ILU_LIBRARY)
        add_library(DevIL::ILU STATIC IMPORTED)
        set_target_properties(DevIL::ILU PROPERTIES
            IMPORTED_LOCATION "${_ILU_LIBRARY}"
            INTERFACE_INCLUDE_DIRECTORIES "${_DEVIL_PREFIX}/include"
            INTERFACE_COMPILE_DEFINITIONS "IL_STATIC_LIB"
            INTERFACE_LINK_LIBRARIES "DevIL::IL"
        )
    endif()

    unset(_IL_IMPLIB CACHE)
    unset(_IL_LIBRARY CACHE)
    unset(_ILU_IMPLIB CACHE)
    unset(_ILU_LIBRARY CACHE)
endif()

set(DevIL_FOUND TRUE)
set(IL_FOUND TRUE)
set(IL_INCLUDE_DIR "${_DEVIL_PREFIX}/include")
set(IL_LIBRARIES DevIL::IL)
set(ILU_LIBRARIES DevIL::ILU)
unset(_DEVIL_PREFIX)
]=])
    message(STATUS "Created DevILConfig.cmake")
endif()

# ---------------------------------------------------------------------------
# openal-soft
# ---------------------------------------------------------------------------
# When openal-soft is built as a shared library, fmt is statically linked
# into it.  Remove find_dependency(fmt) so consumers don't need fmt.

set(_file "${SHARE_DIR}/openal-soft/OpenALConfig.cmake")
if(EXISTS "${_file}")
    file(READ "${_file}" _contents)
    string(REPLACE "find_dependency(fmt CONFIG)" "" _contents "${_contents}")
    file(WRITE "${_file}" "${_contents}")
    message(STATUS "Fixed OpenALConfig.cmake (removed fmt dependency)")
endif()

# ---------------------------------------------------------------------------
# Find*.cmake wrapper modules
# ---------------------------------------------------------------------------
# cmake's built-in Find modules (FindFreetype, FindTIFF, etc.) run in
# MODULE mode before CONFIG mode, bypassing our fixed config files.
# These wrappers try CONFIG mode first, falling back to the built-in.
# Consumer adds <install_prefix>/cmake/modules to CMAKE_MODULE_PATH.

file(WRITE "${_MODULES_DIR}/FindFreetype.cmake" [=[
find_package(Freetype CONFIG QUIET)
if(TARGET Freetype::Freetype)
    set(FREETYPE_FOUND TRUE)
    set(Freetype_FOUND TRUE)
    get_target_property(FREETYPE_INCLUDE_DIRS Freetype::Freetype INTERFACE_INCLUDE_DIRECTORIES)
    set(FREETYPE_LIBRARIES Freetype::Freetype)
    return()
endif()
include(${CMAKE_ROOT}/Modules/FindFreetype.cmake)
]=])
message(STATUS "Installed FindFreetype.cmake wrapper")

file(WRITE "${_MODULES_DIR}/FindTIFF.cmake" [=[
find_package(TIFF CONFIG QUIET)
if(TARGET TIFF::TIFF)
    set(TIFF_FOUND TRUE)
    get_target_property(TIFF_INCLUDE_DIRS TIFF::TIFF INTERFACE_INCLUDE_DIRECTORIES)
    set(TIFF_LIBRARIES TIFF::TIFF)
    return()
endif()
include(${CMAKE_ROOT}/Modules/FindTIFF.cmake)
]=])
message(STATUS "Installed FindTIFF.cmake wrapper")

file(WRITE "${_MODULES_DIR}/FindFontconfig.cmake" [=[
find_package(Fontconfig CONFIG QUIET)
if(TARGET Fontconfig::Fontconfig)
    set(Fontconfig_FOUND TRUE)
    set(FONTCONFIG_FOUND TRUE)
    get_target_property(Fontconfig_INCLUDE_DIRS Fontconfig::Fontconfig INTERFACE_INCLUDE_DIRECTORIES)
    set(Fontconfig_LIBRARIES Fontconfig::Fontconfig)
    return()
endif()
if(EXISTS "${CMAKE_ROOT}/Modules/FindFontconfig.cmake")
    include(${CMAKE_ROOT}/Modules/FindFontconfig.cmake)
endif()
]=])
message(STATUS "Installed FindFontconfig.cmake wrapper")

file(WRITE "${_MODULES_DIR}/FindDevIL.cmake" [=[
find_package(DevIL CONFIG QUIET)
if(TARGET DevIL::IL)
    set(DevIL_FOUND TRUE)
    set(IL_FOUND TRUE)
    get_target_property(IL_INCLUDE_DIR DevIL::IL INTERFACE_INCLUDE_DIRECTORIES)
    set(IL_LIBRARIES DevIL::IL)
    set(ILU_LIBRARIES DevIL::ILU)
    return()
endif()
include(${CMAKE_ROOT}/Modules/FindDevIL.cmake)
]=])
message(STATUS "Installed FindDevIL.cmake wrapper")

# ---------------------------------------------------------------------------
# FindPNG.cmake wrapper
# ---------------------------------------------------------------------------
# libpng ships a PNGConfig.cmake (share/png/) but cmake's built-in FindPNG
# module runs in MODULE mode and finds the system libpng16.so instead of our
# static libpng16.a.  CONFIG mode via find_package(PNG CONFIG) can also pick
# up a system PNGConfig.cmake if CMAKE_PREFIX_PATH isn't populated yet.
#
# The wrapper is self-sufficient: it uses CMAKE_CURRENT_LIST_DIR (the
# cmake/modules/ directory) to derive the install prefix and directly creates
# PNG::PNG pointing to our libpng16.a — no reliance on PREFIX_PATH ordering.

file(WRITE "${_MODULES_DIR}/FindPNG.cmake" [=[
# Try CONFIG mode first in case the caller set up CMAKE_PREFIX_PATH already.
# Guard against accidentally picking up a system PNGConfig by checking that
# the resolved library is a static archive.
find_package(PNG CONFIG QUIET)
if(TARGET PNG::PNG)
    get_target_property(_png_loc PNG::PNG IMPORTED_LOCATION)
    if(NOT _png_loc)
        # INTERFACE target — follow through to png_static
        get_target_property(_png_iface PNG::PNG INTERFACE_LINK_LIBRARIES)
        foreach(_t IN LISTS _png_iface)
            if(TARGET "${_t}")
                get_target_property(_png_loc "${_t}" IMPORTED_LOCATION)
                if(_png_loc)
                    break()
                endif()
            endif()
        endforeach()
        unset(_png_iface)
        unset(_t)
    endif()
    if(_png_loc MATCHES "\\.a$")
        set(PNG_FOUND TRUE)
        get_target_property(PNG_PNG_INCLUDE_DIR PNG::PNG INTERFACE_INCLUDE_DIRECTORIES)
        set(PNG_INCLUDE_DIRS "${PNG_PNG_INCLUDE_DIR}")
        set(PNG_LIBRARIES PNG::PNG)
        unset(_png_loc)
        return()
    endif()
    unset(_png_loc)
    # CONFIG found a shared lib — drop it and build our own target below.
endif()

# Derive install prefix from our location: cmake/modules/ → ../../
get_filename_component(_recoil_prefix "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
find_library(_png_lib NAMES png16 png
    PATHS "${_recoil_prefix}/lib"
    NO_DEFAULT_PATH)
if(_png_lib AND _png_lib MATCHES "\\.a$")
    if(NOT TARGET PNG::png_static)
        add_library(PNG::png_static STATIC IMPORTED GLOBAL)
        set_target_properties(PNG::png_static PROPERTIES
            IMPORTED_LOCATION "${_png_lib}"
            INTERFACE_INCLUDE_DIRECTORIES "${_recoil_prefix}/include/libpng16"
            INTERFACE_LINK_LIBRARIES "ZLIB::ZLIB;m")
    endif()
    if(NOT TARGET PNG::PNG)
        add_library(PNG::PNG INTERFACE IMPORTED GLOBAL)
        set_target_properties(PNG::PNG PROPERTIES
            INTERFACE_LINK_LIBRARIES "PNG::png_static")
    endif()
    set(PNG_FOUND TRUE)
    set(PNG_PNG_INCLUDE_DIR "${_recoil_prefix}/include/libpng16")
    set(PNG_INCLUDE_DIRS "${_recoil_prefix}/include/libpng16")
    set(PNG_LIBRARIES PNG::PNG)
    unset(_png_lib CACHE)
    unset(_recoil_prefix)
    return()
endif()
unset(_png_lib CACHE)
unset(_recoil_prefix)

include(${CMAKE_ROOT}/Modules/FindPNG.cmake)
]=])
message(STATUS "Installed FindPNG.cmake wrapper")

# ---------------------------------------------------------------------------
# FindJPEG.cmake wrapper
# ---------------------------------------------------------------------------
# libjpeg-turbo exports libjpeg-turbo::jpeg-static, not the canonical
# JPEG::JPEG target that cmake's FindJPEG module creates.  DevILConfig.cmake
# lists JPEG::JPEG in INTERFACE_LINK_LIBRARIES, so without this wrapper
# JPEG::JPEG is either undefined or resolves to the system libjpeg.so.
# Same self-sufficient prefix-relative fallback as FindPNG.cmake above.

file(WRITE "${_MODULES_DIR}/FindJPEG.cmake" [=[
find_package(libjpeg-turbo CONFIG QUIET)
if(TARGET libjpeg-turbo::jpeg-static)
    if(NOT TARGET JPEG::JPEG)
        add_library(JPEG::JPEG INTERFACE IMPORTED GLOBAL)
        set_target_properties(JPEG::JPEG PROPERTIES
            INTERFACE_LINK_LIBRARIES "libjpeg-turbo::jpeg-static")
    endif()
    set(JPEG_FOUND TRUE)
    get_target_property(JPEG_INCLUDE_DIRS libjpeg-turbo::jpeg-static INTERFACE_INCLUDE_DIRECTORIES)
    set(JPEG_LIBRARIES JPEG::JPEG)
    return()
endif()

# Prefix-relative fallback: cmake/modules/ → ../../
get_filename_component(_recoil_prefix "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
find_library(_jpeg_lib NAMES jpeg
    PATHS "${_recoil_prefix}/lib"
    NO_DEFAULT_PATH)
if(_jpeg_lib AND _jpeg_lib MATCHES "\\.a$")
    if(NOT TARGET JPEG::JPEG)
        add_library(JPEG::JPEG STATIC IMPORTED GLOBAL)
        set_target_properties(JPEG::JPEG PROPERTIES
            IMPORTED_LOCATION "${_jpeg_lib}"
            INTERFACE_INCLUDE_DIRECTORIES "${_recoil_prefix}/include")
    endif()
    set(JPEG_FOUND TRUE)
    set(JPEG_INCLUDE_DIRS "${_recoil_prefix}/include")
    set(JPEG_LIBRARIES JPEG::JPEG)
    unset(_jpeg_lib CACHE)
    unset(_recoil_prefix)
    return()
endif()
unset(_jpeg_lib CACHE)
unset(_recoil_prefix)

include(${CMAKE_ROOT}/Modules/FindJPEG.cmake)
]=])
message(STATUS "Installed FindJPEG.cmake wrapper")

# ---------------------------------------------------------------------------
# recoil-libs.cmake — consumer setup file
# ---------------------------------------------------------------------------
# The engine includes this file once:
#   include(<install_prefix>/recoil-libs.cmake)
# It adds the install prefix to CMAKE_PREFIX_PATH and sets
# CMAKE_FIND_PACKAGE_PREFER_CONFIG so that our fixed CONFIG files
# (freetype, tiff, fontconfig, devil, png, jpeg) take priority over cmake's
# built-in Find modules which lack transitive dependency info.
# It also adds cmake/modules to CMAKE_MODULE_PATH as a fallback.

file(WRITE "${_INSTALL_PREFIX}/recoil-libs.cmake" [=[
get_filename_component(_RECOIL_LIBS_PREFIX "${CMAKE_CURRENT_LIST_DIR}" ABSOLUTE)

if(NOT _RECOIL_LIBS_PREFIX IN_LIST CMAKE_PREFIX_PATH)
    list(APPEND CMAKE_PREFIX_PATH "${_RECOIL_LIBS_PREFIX}")
endif()

set(_RECOIL_MODULES "${_RECOIL_LIBS_PREFIX}/cmake/modules")
if(IS_DIRECTORY "${_RECOIL_MODULES}" AND NOT _RECOIL_MODULES IN_LIST CMAKE_MODULE_PATH)
    list(INSERT CMAKE_MODULE_PATH 0 "${_RECOIL_MODULES}")
endif()
unset(_RECOIL_MODULES)

set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)

unset(_RECOIL_LIBS_PREFIX)
]=])
message(STATUS "Installed recoil-libs.cmake")
