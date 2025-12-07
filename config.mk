# Configuration for BugleOS minirootfs build
ARCHITECTURE	?= $(shell uname -m)
VERSION			?= 1.0.0
TARGET			:= $(ARCHITECTURE)-linux-musl
PREFIX			?= $(PWD)/toolchain
SYSROOT			?= $(PWD)/sysroot
ROOTFS			?= $(PWD)/build/rootfs
SOURCES			?= $(PWD)/sources
BUILD			?= $(PWD)/build
OUTPUT			?= $(PWD)/output

# Versions of components
BINUTILS_VERSION ?= 2.41
GCC_VERSION ?= 13.2.0
LINUX_VERSION ?= 6.1.60
MUSL_VERSION ?= 1.2.4
BUSYBOX_VERSION ?= 1.36.1
