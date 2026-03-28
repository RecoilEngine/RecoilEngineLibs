set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)
set(VCPKG_BUILD_TYPE release)

# Pass through PATH to find MinGW cross-compiler
set(VCPKG_ENV_PASSTHROUGH PATH)

# Compiler flags for generic x86-64
# _WIN32_WINNT=0x0601 = Windows 7+; required by curl and other ports
set(VCPKG_C_FLAGS "-mtune=generic -march=x86-64 -D_WIN32_WINNT=0x0601")
set(VCPKG_CXX_FLAGS "-mtune=generic -march=x86-64 -D_WIN32_WINNT=0x0601")
set(VCPKG_LINKER_FLAGS "")

# C++17 standard requirement
set(VCPKG_CMAKE_CONFIGURE_OPTIONS
    -DCMAKE_CXX_STANDARD=17
    -DCMAKE_CXX_STANDARD_REQUIRED=ON
)

# This tells vcpkg to use the MinGW toolchain
# vcpkg automatically loads scripts/toolchains/mingw.cmake when this is set
set(VCPKG_CMAKE_SYSTEM_NAME MinGW)
