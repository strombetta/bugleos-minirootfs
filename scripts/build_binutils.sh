#!/bin/sh
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
#
# build_binutils.sh - Build and install a cross Binutils toolchain configured
# for the provided target triple and sysroot.
set -eu

# build_binutils.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD BINUTILS_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
BINUTILS_VERSION=$7

SRC_ARCHIVE="${SOURCES}/binutils-${BINUTILS_VERSION}.tar.xz"
BUILD_DIR="${BUILD}/binutils"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -xf "$SRC_ARCHIVE" -C "$BUILD_DIR" --strip-components=1
cd "$BUILD_DIR"

./configure \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-sysroot="$SYSROOT" \
    --disable-nls \
    --disable-werror

make -j$(nproc)
make install
