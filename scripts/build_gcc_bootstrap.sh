#!/bin/sh
set -eu

# build_gcc_bootstrap.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD GCC_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
GCC_VERSION=$7

SRC_ARCHIVE="${SOURCES}/gcc-${GCC_VERSION}.tar.xz"
BUILD_DIR="${BUILD}/gcc-bootstrap"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -xf "$SRC_ARCHIVE" -C "$BUILD_DIR" --strip-components=1
cd "$BUILD_DIR"

./contrib/download_prerequisites

./configure \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-sysroot="$SYSROOT" \
    --enable-languages=c \
    --without-headers \
    --disable-multilib \
    --disable-nls

# Build the compiler first
make all-gcc -j$(nproc)
make install-gcc

# Build and install libgcc so that later stages (like musl) have the
# compiler builtins they need during linking
make all-target-libgcc -j$(nproc)
make install-target-libgcc
