#!/bin/sh
set -eu

# build_musl.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD MUSL_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
MUSL_VERSION=$7

SRC_ARCHIVE="${SOURCES}/musl-${MUSL_VERSION}.tar.gz"
BUILD_DIR="${BUILD}/musl"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -xf "$SRC_ARCHIVE" -C "$BUILD_DIR" --strip-components=1
cd "$BUILD_DIR"

CC="${PREFIX}/bin/${TARGET}-gcc" ./configure \
    --prefix=/usr \
    --target="$TARGET"

make -j$(nproc)
DESTDIR="$SYSROOT" make install
