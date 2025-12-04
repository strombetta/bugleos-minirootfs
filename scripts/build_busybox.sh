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
sed -e 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' -i .config
sed -e 's/# CONFIG_STATIC_LIBGCC is not set/CONFIG_STATIC_LIBGCC=y/' -i .config
sed -e 's/CONFIG_TC=y/# CONFIG_TC is not set/' -i .config
sed -e 's/CONFIG_BASE32=y/# CONFIG_BASE32 is not set/' -i .config
sed -e 's/CONFIG_CONSPY=y/# CONFIG_CONSPY is not set/' -i .config
sed -e 's/CONFIG_CPIO=y/# CONFIG_CPIO is not set/' -i .config
sed -e 's/CONFIG_CTTYHACK=y/# CONFIG_CTTYHACK is not set/' -i .config
sed -e 's/CONFIG_HUSH=y/# CONFIG_HUSH is not set/' -i .config
sed -e 's/CONFIG_MT=y/# CONFIG_MT is not set/' -i .config
sed -e 's/CONFIG_RESUME=y/# CONFIG_RESUME is not set/' -i .config
sed -e 's/CONFIG_RPM=y/# CONFIG_RPM is not set/' -i .config
sed -e 's/CONFIG_SCRIPTREPLAY=y/# CONFIG_SCRIPTREPLAY is not set/' -i .config
sed -e 's/CONFIG_SETARCH=y/# CONFIG_SETARCH is not set/' -i .config
sed -e 's/CONFIG_VI=y/# CONFIG_VI is not set/' -i .config
		
make -C "$SOURCE_DIR" O="$BUILD_DIR" CROSS_COMPILE="${TARGET}-" CC="${PREFIX}/bin/${TARGET}-gcc" AR="${PREFIX}/bin/${TARGET}-ar" STRIP="${PREFIX}/bin/${TARGET}-strip" -j$(nproc)
make -C "$SOURCE_DIR" O="$BUILD_DIR" CROSS_COMPILE="${TARGET}-" CC="${PREFIX}/bin/${TARGET}-gcc" AR="${PREFIX}/bin/${TARGET}-ar" STRIP="${PREFIX}/bin/${TARGET}-strip" CONFIG_PREFIX="$ROOTFS" install
