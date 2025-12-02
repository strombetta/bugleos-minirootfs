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

# Default to the host architecture unless ARCH is provided by the caller.
HOST_ARCH=$(uname -m)
BUILD_ARCH=${ARCH:-$HOST_ARCH}

SRC_ARCHIVE="${SOURCES}/linux-${LINUX_VERSION}.tar.xz"
BUILD_DIR="${BUILD}/linux-headers"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -xf "$SRC_ARCHIVE" -C "$BUILD_DIR" --strip-components=1
cd "$BUILD_DIR"

make ARCH="$BUILD_ARCH" INSTALL_HDR_PATH="$SYSROOT/usr" headers_install
