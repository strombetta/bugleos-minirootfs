#!/bin/sh
# Copyright (c) 2025 Sebastiano Trombetta
# SPDX-License-Identifier: MIT
#
# download_sources.sh - Download the source archives required for building the
# cross toolchain and userland components.
set -eu

# download_sources.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD BINUTILS_VERSION GCC_VERSION LINUX_VERSION MUSL_VERSION BUSYBOX_VERSION
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6
BINUTILS_VERSION=$7
GCC_VERSION=$8
LINUX_VERSION=$9
MUSL_VERSION=${10}
BUSYBOX_VERSION=${11}

# URLs
BINUTILS_URL="https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
GCC_URL="https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"
LINUX_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${LINUX_VERSION}.tar.xz"
MUSL_URL="https://musl.libc.org/releases/musl-${MUSL_VERSION}.tar.gz"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

mkdir -p "${SOURCES}"

fetch() {
    url=$1
    dest=$2
    if [ -f "$dest" ]; then
        echo "Skipping download of $dest (already exists)"
    else
        echo "Downloading $url"
        wget -O "$dest" "$url"
    fi
}

fetch "$BINUTILS_URL" "${SOURCES}/binutils-${BINUTILS_VERSION}.tar.xz"
fetch "$GCC_URL" "${SOURCES}/gcc-${GCC_VERSION}.tar.xz"
fetch "$LINUX_URL" "${SOURCES}/linux-${LINUX_VERSION}.tar.xz"
fetch "$MUSL_URL" "${SOURCES}/musl-${MUSL_VERSION}.tar.gz"
fetch "$BUSYBOX_URL" "${SOURCES}/busybox-${BUSYBOX_VERSION}.tar.bz2"
