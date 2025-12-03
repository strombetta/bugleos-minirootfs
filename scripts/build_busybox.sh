#!/bin/sh
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
#
# build_busybox.sh - Build and install BusyBox into the target sysroot for the
# specified cross-compilation target.
set -eu

# build_busybox.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD BUSYBOX_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
BUSYBOX_VERSION=$7
case "$TARGET" in
	aarch64-*)
        KERNEL_ARCH="arm64"
        ;;
    x86_64-*)
        KERNEL_ARCH="x86"
        ;;
    riscv64-*)
        KERNEL_ARCH="riscv"
        ;;
    *)
        echo "Error: unsupported target '$TARGET'; must be one of: aarch64-*, x86_64-*, riscv64-*." >&2
        exit 1
        ;;
esac

SRC_ARCHIVE="${SOURCES}/busybox-${BUSYBOX_VERSION}.tar.bz2"
SOURCE_DIR="${SOURCES}/busybox-${BUSYBOX_VERSION}"
BUILD_DIR="${BUILD}/busybox"

rm -rf "$SOURCE_DIR"
mkdir -p "$SOURCE_DIR"
tar -xf "$SRC_ARCHIVE" -C "$SOURCE_DIR" --strip-components=1

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

make -C "$SOURCE_DIR" O="$BUILD_DIR" ARCH="$KERNEL_ARCH" CROSS_COMPILE="${TARGET}-" distclean || true
make -C "$SOURCE_DIR" O="$BUILD_DIR" ARCH="$KERNEL_ARCH" CROSS_COMPILE="${TARGET}-" defconfig

# Enable static build
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

make CROSS_COMPILE="${TARGET}-" -j$(nproc)
make CROSS_COMPILE="${TARGET}-" CONFIG_PREFIX="$ROOTFS" install
