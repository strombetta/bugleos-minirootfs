#!/bin/sh
set -eu

# build_busybox.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD BUSYBOX_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
BUSYBOX_VERSION=$7

SRC_ARCHIVE="${SOURCES}/busybox-${BUSYBOX_VERSION}.tar.bz2"
BUILD_DIR="${BUILD}/busybox"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -xf "$SRC_ARCHIVE" -C "$BUILD_DIR" --strip-components=1
cd "$BUILD_DIR"

make distclean || true
make defconfig

# Enable static build
sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

make CROSS_COMPILE="${TARGET}-" -j$(nproc)
make CROSS_COMPILE="${TARGET}-" CONFIG_PREFIX="$ROOTFS" install
