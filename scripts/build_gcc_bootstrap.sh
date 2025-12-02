#!/bin/sh
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
#
# build_gcc_bootstrap.sh - Prepare a GCC bootstrap compiler and libgcc for
# cross-compiling with a sysroot. Extracts the GCC sources into a build
# directory and builds only the compiler and libgcc needed for subsequent
# stages.
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
SOURCE_DIR="$(SOURCES)/gcc-${GCC_VERSION}"
BUILD_DIR="${BUILD}/gcc-bootstrap"

rm -rf "$SOURCE_DIR"
mkdir -p "$SOURCE_DIR"
tar -xf "$SRC_ARCHIVE" -C "$SOURCE_DIR" --strip-components=1

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

$SOURCE_DIR/configure \
    --target="$TARGET" \
    --prefix="$PREFIX" \
    --with-sysroot="$SYSROOT" \
    --without-headers \
	--with-native-system-header-dir=/usr/include \
	--with-newlib \
	--disable-nls \
	--disable-shared \
	--disable-threads \
	--disable-libatomic \
	--disable-libgomp \
	--disable-libquadmath \
	--disable-libssp \
	--disable-libvtv \
	--disable-multilib \
	--enable-languages=c \
    --disable-multilib

# Build the compiler first
make all-gcc all-target-libgcc -j$(nproc)
# make install-gcc install-target-libgcc

# Build and install libgcc so that later stages (like musl) have the
# compiler builtins they need during linking
# make  -j$(nproc)
# make 
