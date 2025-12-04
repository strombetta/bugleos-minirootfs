# Makefile for BugleOS minirootfs
# BugleOS v1.0.0
# Copyright (C) Sebastiano Trombetta. All rights reserved.

include config.mk

HOST_ARCH 				?= $(shell uname -m)
BUILD_ARCH 				?= $(if $(ARCH),$(ARCH),$(HOST_ARCH))
export BUILD_ARCH

BINUTILS_STAMP			:=$(BUILD)/.binutils.stamp
GCC_BOOTSTRAP_STAMP		:=$(BUILD)/.gcc-bootstrap.stamp
KERNEL_HEADERS_STAMP	:=$(BUILD)/.kernel-headers.stamp
MUSL_STAMP				:=$(BUILD)/.musl.stamp
GCC_FINAL_STAMP			:=$(BUILD)/.gcc-final.stamp
BUSYBOX_STAMP			:=$(BUILD)/.busybox.stamp
ROOTFS_STAMP			:=$(BUILD)/.rootfs.stamp
IMAGE_TARBALL			:=$(OUTPUT)/bugleos-minirootfs-$(VERSION)-$(ARCHITECTURE).tar.gz
DOWNLOAD_STAMP			:=$(SOURCES)/.downloaded

.PHONY: all download test clean distclean

all: $(IMAGE_TARBALL)

download: $(DOWNLOAD_STAMP)

# Download all sources
SCRIPTS:=scripts

$(DOWNLOAD_STAMP): $(SCRIPTS)/download_sources.sh config.mk | $(SOURCES)
	@sh $(SCRIPTS)/download_sources.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(BINUTILS_VERSION)" "$(GCC_VERSION)" "$(LINUX_VERSION)" "$(MUSL_VERSION)" "$(BUSYBOX_VERSION)"
	@touch $@

$(SOURCES):
	@mkdir -p $@

$(BINUTILS_STAMP): $(DOWNLOAD_STAMP) $(SCRIPTS)/build_binutils.sh config.mk
	@sh $(SCRIPTS)/build_binutils.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(BINUTILS_VERSION)"
	@touch $@

$(KERNEL_HEADERS_STAMP): $(DOWNLOAD_STAMP) $(SCRIPTS)/install_kernel_headers.sh config.mk
	@sh $(SCRIPTS)/install_kernel_headers.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(LINUX_VERSION)"
	@touch $@

$(GCC_BOOTSTRAP_STAMP): $(BINUTILS_STAMP) $(KERNEL_HEADERS_STAMP) $(SCRIPTS)/build_gcc_bootstrap.sh config.mk
	@sh $(SCRIPTS)/build_gcc_bootstrap.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(GCC_VERSION)"
	@touch $@

$(MUSL_STAMP): $(GCC_BOOTSTRAP_STAMP) $(KERNEL_HEADERS_STAMP) $(SCRIPTS)/build_musl.sh config.mk
	@sh $(SCRIPTS)/build_musl.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(MUSL_VERSION)"
	@touch $@

$(GCC_FINAL_STAMP): $(MUSL_STAMP) $(SCRIPTS)/build_gcc_final.sh config.mk
	@sh $(SCRIPTS)/build_gcc_final.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(GCC_VERSION)"
	@touch $@

$(BUSYBOX_STAMP): $(GCC_FINAL_STAMP) $(SCRIPTS)/build_busybox.sh config.mk
	@sh $(SCRIPTS)/build_busybox.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(BUSYBOX_VERSION)"
	@touch $@


$(ROOTFS_STAMP): $(BUSYBOX_STAMP) $(SCRIPTS)/create_rootfs_layout.sh config.mk
@sh $(SCRIPTS)/create_rootfs_layout.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(VERSION)"
@touch $@

$(IMAGE_TARBALL): $(ROOTFS_STAMP) | $(OUTPUT)
	@mkdir -p $(OUTPUT)
	@sh -c 'chown -R 0:0 "$(ROOTFS)" 2>/dev/null || true'
	@tar --numeric-owner --numeric-owner --owner=0 --group=0 -czf $(IMAGE_TARBALL) -C $(ROOTFS) .

$(OUTPUT):
	@mkdir -p $@

# Testing
TESTS:=tests/test_toolchain.sh tests/test_busybox.sh tests/test_rootfs_layout.sh tests/test_image.sh
test: $(IMAGE_TARBALL)
	@set -e; \
		for t in $(TESTS); do \
		echo "Running $$t"; \
		TARGET="$(TARGET)" PREFIX="$(PREFIX)" SYSROOT="$(SYSROOT)" ROOTFS="$(ROOTFS)" OUTPUT="$(OUTPUT)" sh $$t; \
	done

# Cleaning
clean:
	rm -rf $(BUILD)/binutils $(BUILD)/kernel-headers $(BUILD)/gcc-bootstrap $(BUILD)/gcc-final $(BUILD)/musl $(BUILD)/busybox $(ROOTFS)
	rm -f $(BINUTILS_STAMP) $(GCC_BOOTSTRAP_STAMP) $(KERNEL_HEADERS_STAMP) $(MUSL_STAMP) $(GCC_FINAL_STAMP) $(BUSYBOX_STAMP) $(ROOTFS_STAMP)

# Be careful with distclean; keep sources by default
# Remove toolchain and sysroot as well
distclean: clean
	rm -rf $(PREFIX) $(SYSROOT) $(IMAGE_TARBALL) $(DOWNLOAD_STAMP)

