# vcpkg Binary Caching Guide

This document explains how to use vcpkg binary caching to avoid rebuilding packages on every Docker container run.

## Problem

When running `docker run --rm spring-static-libs-test bash -c "./vcpkg/build.sh generic"`, each container run starts fresh with no persisted vcpkg build cache. This causes all packages to be rebuilt every time, which is time-consuming.

## Solution

vcpkg binary caching stores compiled package binaries in a cache directory. When the same package (with the same ABI hash) is requested again, vcpkg restores it from cache instead of rebuilding.

## Quick Start

### Option 1: Host Directory Volume Mount (Recommended)

```bash
# Create a cache directory on your host
mkdir -p ~/.cache/vcpkg-binary-cache

# Build with cache persistence
docker run --rm \
    -v ~/.cache/vcpkg-binary-cache:/cache/vcpkg-binary-cache \
    spring-static-libs-test \
    bash -c "./vcpkg/build.sh generic"
```

### Option 2: Docker Named Volume

```bash
# Create a named Docker volume
docker volume create vcpkg-binary-cache

# Build with named volume
docker run --rm \
    -v vcpkg-binary-cache:/cache/vcpkg-binary-cache \
    spring-static-libs-test \
    bash -c "./vcpkg/build.sh generic"
```

### Option 3: Custom Cache Location

```bash
# Use a custom cache location
docker run --rm \
    -e VCPKG_BINARY_CACHE=/custom/cache/path \
    -v /my/custom/cache:/custom/cache/path \
    spring-static-libs-test \
    bash -c "./vcpkg/build.sh generic"
```

## How It Works

1. **First run**: vcpkg builds packages from source and stores binaries in `/cache/vcpkg-binary-cache`
2. **Subsequent runs**: vcpkg checks the cache first and restores packages if the ABI hash matches
3. **Cache invalidation**: If package version, triplet, or compiler flags change, vcpkg automatically rebuilds

## Cache Location

| Environment | Default Location |
|-------------|------------------|
| Docker container | `/cache/vcpkg-binary-cache` |
| Host (when mounted) | User-specified (e.g., `~/.cache/vcpkg-binary-cache`) |

Override with `VCPKG_BINARY_CACHE` environment variable.

## Multiple Architectures

The cache handles different architectures automatically because vcpkg uses ABI-based hashing:

```bash
# Build for generic x64
docker run --rm \
    -v ~/.cache/vcpkg-binary-cache:/cache/vcpkg-binary-cache \
    spring-static-libs-test \
    bash -c "./vcpkg/build.sh generic"

# Build for Nehalem (uses separate cache entries)
docker run --rm \
    -v ~/.cache/vcpkg-binary-cache:/cache/vcpkg-binary-cache \
    spring-static-libs-test \
    bash -c "./vcpkg/build.sh nehalem"
```

## Expected Performance

| Scenario | Time |
|----------|------|
| First build (no cache) | 30-60 minutes |
| Subsequent build (cache hit) | 1-5 minutes |
| Partial rebuild (some packages changed) | Varies |

## Cache Size

The binary cache typically uses 2-4 GB of disk space, depending on the number of architectures built.

To check cache size:
```bash
du -sh ~/.cache/vcpkg-binary-cache
```

## Clearing the Cache

To force a complete rebuild, delete the cache directory:

```bash
# For host directory mount
rm -rf ~/.cache/vcpkg-binary-cache/*

# For Docker named volume
docker volume rm vcpkg-binary-cache
```

## Troubleshooting

### Cache Not Being Used

1. **Verify volume mount**: Ensure the volume is mounted correctly
   ```bash
   docker run --rm \
       -v ~/.cache/vcpkg-binary-cache:/cache/vcpkg-binary-cache \
       spring-static-libs-test \
       ls -la /cache/vcpkg-binary-cache
   ```

2. **Check permissions**: The cache directory should be writable
   ```bash
   # Fix permissions if needed
   chmod 777 ~/.cache/vcpkg-binary-cache
   ```

3. **Verify environment variable**: Check that `VCPKG_BINARY_CACHE` is set
   ```bash
   docker run --rm spring-static-libs-test bash -c 'echo $VCPKG_BINARY_CACHE'
   ```

### Packages Still Rebuilding

This is expected when:
- Package version in `vcpkg.json` changed
- vcpkg baseline was updated
- Triplet configuration changed
- Overlay ports were modified
- Compiler or compiler flags changed

### Out of Disk Space

The cache can grow large. To clean up:
```bash
# Remove old cache entries
rm -rf ~/.cache/vcpkg-binary-cache
mkdir -p ~/.cache/vcpkg-binary-cache
```

## Advanced Configuration

### Using vcpkg Environment Variable

Instead of the build script's `--binarysource` flag, you can use vcpkg's native environment variable:

```bash
docker run --rm \
    -e VCPKG_BINARY_SOURCES="clear;files,/cache/vcpkg-binary-cache,readwrite" \
    -v ~/.cache/vcpkg-binary-cache:/cache/vcpkg-binary-cache \
    spring-static-libs-test \
    bash -c "./vcpkg/build.sh generic"
```

### Multiple Cache Sources

vcpkg supports multiple cache sources with read/write priorities:

```bash
# Read from shared cache, write to local
VCPKG_BINARY_SOURCES="clear;files,/shared/cache,read;files,/local/cache,readwrite"
```

### NuGet-based Caching

For team sharing, consider NuGet-based caching (see [vcpkg binary caching documentation](https://learn.microsoft.com/en-us/vcpkg/users/binarycaching)).

## Related Files

- [`build.sh`](build.sh) - Build script with binary caching support
- [`Dockerfile.vcpkg`](../Dockerfile.vcpkg) - Docker image with cache directory setup
- [`vcpkg.json`](vcpkg.json) - Package manifest

## References

- [vcpkg Binary Caching Documentation](https://learn.microsoft.com/en-us/vcpkg/users/binarycaching)
- [vcpkg Binary Caching Specification](https://learn.microsoft.com/en-us/vcpkg/reference/binarycaching)
