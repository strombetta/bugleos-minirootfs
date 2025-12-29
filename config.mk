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
PREFIX ?= $(PWD)/toolchain
SYSROOT ?= $(PWD)/sysroot
ROOTFS ?= $(PWD)/build/rootfs
SOURCES ?= $(PWD)/sources
BUILD ?= $(PWD)/build
OUTPUT ?= $(PWD)/output

