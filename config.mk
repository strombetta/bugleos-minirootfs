# Configuration for BugleOS minirootfs build
ARCH ?= $(shell uname -m)
ARCHITECTURE ?= $(ARCH)
VERSION ?= 1.0.0

ifeq ($(ARCHITECTURE),arm64)
TARGET := aarch64-linux-musl
else ifeq ($(ARCHITECTURE),x86)
TARGET := i686-linux-musl
else ifeq ($(ARCHITECTURE),amd64)
TARGET := x86_64-linux-musl
else
TARGET := $(ARCHITECTURE)-linux-musl
endif
PREFIX_BOOTSTRAP ?= $(PWD)/toolchain-bootstrap
SYSROOT_BOOTSTRAP ?= $(PWD)/sysroot-bootstrap
PREFIX ?= $(PWD)/toolchain
SYSROOT ?= $(PWD)/sysroot
ROOTFS ?= $(PWD)/build/rootfs
SOURCES ?= $(PWD)/sources
BUILD ?= $(PWD)/build
OUTPUT ?= $(PWD)/output

# Versions of components
BINUTILS_VERSION ?= 2.41
GCC_VERSION ?= 13.2.0
LINUX_VERSION ?= 6.1.60
MUSL_VERSION ?= 1.2.4
BUSYBOX_VERSION ?= 1.36.1
