#!/bin/sh
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
#
# install_kernel_headers.sh - Install Linux kernel headers into the target
# sysroot for use by subsequent toolchain stages.
set -eu

# install_kernel_headers.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD LINUX_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
LINUX_VERSION=$7
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

SRC_ARCHIVE="${SOURCES}/linux-${LINUX_VERSION}.tar.xz"
BUILD_DIR="${BUILD}/kernel-headers"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -xf "$SRC_ARCHIVE" -C "$BUILD_DIR" --strip-components=1
cd "$BUILD_DIR"

make ARCH="$KERNEL_ARCH" INSTALL_HDR_PATH="$SYSROOT/usr" headers_install
