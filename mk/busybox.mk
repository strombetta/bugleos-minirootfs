#
# Copyright (c) Sebastiano Trombetta. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))
include $(abspath $(dir $(THIS_MAKEFILE))/config.mk)
include $(abspath $(dir $(THIS_MAKEFILE))/helpers.mk)

BUSYBOX_VERSION ?= 1.37.0
BUSYBOX_URL := https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_TAR := busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_TAR_PATH := $(DOWNLOADS_DIR)/$(BUSYBOX_TAR)
BUSYBOX_SIG := https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2.sig
BUSYBOX_SHA256 := 3311dff32e746499f4df0d5df04d7eb396382d7e108bb9250e7b519b837043a4

TOOLCHAIN_ROOT ?= $(TOOLCHAIN_DIR)
STAGE1_TOOLCHAIN_ROOT ?= $(TOOLCHAIN_DIR)

BUSYBOX_SRC_DIR := $(DOWNLOADS_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_BUILD_DIR := $(BUILDS_DIR)/busybox
BUSYBOX_PATCH := $(ROOT_DIR)/patches/busybox-ls-color.patch

ifeq ($(TARGET_ARCH),aarch64)
BUSYBOX_KERNEL_ARCH := arm64
else ifeq ($(TARGET_ARCH),x86_64)
BUSYBOX_KERNEL_ARCH := x86
else ifeq ($(TARGET_ARCH),riscv64)
BUSYBOX_KERNEL_ARCH := riscv
else
$(error Error: unsupported target '$(TARGET)'; must be one of: aarch64-*, x86_64-*, riscv64-*)
endif

.PHONY: busybox ensure-dirs

busybox: $(PROGRESS_DIR)/.busybox-done

$(PROGRESS_DIR)/.busybox-done: $(PROGRESS_DIR)/.busybox-built
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-built: $(PROGRESS_DIR)/.busybox-unpacked
	$(call do_step,CONFIG,busybox, \
		$(call with_cross_env, \
			rm -rf "$(BUSYBOX_BUILD_DIR)"; \
			mkdir -p "$(BUSYBOX_BUILD_DIR)"; \
			$(MAKE) -C "$(BUSYBOX_SRC_DIR)" O="$(BUSYBOX_BUILD_DIR)" \
				ARCH="$(BUSYBOX_KERNEL_ARCH)" CROSS_COMPILE="$(TARGET)-" distclean || true; \
			$(MAKE) -C "$(BUSYBOX_SRC_DIR)" O="$(BUSYBOX_BUILD_DIR)" \
				ARCH="$(BUSYBOX_KERNEL_ARCH)" CROSS_COMPILE="$(TARGET)-" defconfig; \
			cd "$(BUSYBOX_BUILD_DIR)"; \
			sed -e 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' -i .config; \
			sed -e 's/# CONFIG_STATIC_LIBGCC is not set/CONFIG_STATIC_LIBGCC=y/' -i .config; \
			sed -e 's/CONFIG_TC=y/# CONFIG_TC is not set/' -i .config; \
			sed -e 's/CONFIG_BASE32=y/# CONFIG_BASE32 is not set/' -i .config; \
			sed -e 's/CONFIG_CONSPY=y/# CONFIG_CONSPY is not set/' -i .config; \
			sed -e 's/CONFIG_CPIO=y/# CONFIG_CPIO is not set/' -i .config; \
			sed -e 's/CONFIG_CTTYHACK=y/# CONFIG_CTTYHACK is not set/' -i .config; \
			sed -e 's/CONFIG_HUSH=y/# CONFIG_HUSH is not set/' -i .config; \
			sed -e 's/CONFIG_MT=y/# CONFIG_MT is not set/' -i .config; \
			sed -e 's/CONFIG_RESUME=y/# CONFIG_RESUME is not set/' -i .config; \
			sed -e 's/CONFIG_RPM=y/# CONFIG_RPM is not set/' -i .config; \
			sed -e 's/CONFIG_SCRIPTREPLAY=y/# CONFIG_SCRIPTREPLAY is not set/' -i .config; \
			sed -e 's/CONFIG_SETARCH=y/# CONFIG_SETARCH is not set/' -i .config; \
			sed -e 's/CONFIG_VI=y/# CONFIG_VI is not set/' -i .config), \
		busybox-config)
	$(call do_step,BUILD,busybox, \
		$(call with_cross_env, \
			$(MAKE) -C "$(BUSYBOX_SRC_DIR)" O="$(BUSYBOX_BUILD_DIR)" \
				ARCH="$(BUSYBOX_KERNEL_ARCH)" \
				CROSS_COMPILE="$(TARGET)-" \
				CC="$(TOOLCHAIN_DIR)/bin/$(TARGET)-gcc" \
				AR="$(TOOLCHAIN_DIR)/bin/$(TARGET)-ar" \
				STRIP="$(TOOLCHAIN_DIR)/bin/$(TARGET)-strip" \
				-j"$(JOBS)"), \
		busybox-build)
	$(call do_step,INSTALL,busybox, \
		$(call with_cross_env, \
			$(MAKE) -C "$(BUSYBOX_SRC_DIR)" O="$(BUSYBOX_BUILD_DIR)" \
				ARCH="$(BUSYBOX_KERNEL_ARCH)" \
				CROSS_COMPILE="$(TARGET)-" \
				CC="$(TOOLCHAIN_DIR)/bin/$(TARGET)-gcc" \
				AR="$(TOOLCHAIN_DIR)/bin/$(TARGET)-ar" \
				STRIP="$(TOOLCHAIN_DIR)/bin/$(TARGET)-strip" \
				CONFIG_PREFIX="$(ROOTFS_DIR)" install), \
		busybox-install)
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-unpacked: $(PROGRESS_DIR)/.busybox-verified
	$(call do_step,EXTRACT,busybox, \
		$(call with_host_env, \
			rm -rf "$(BUSYBOX_SRC_DIR)"; \
			mkdir -p "$(BUSYBOX_SRC_DIR)"; \
			"$(TAR)" -xf "$(BUSYBOX_TAR_PATH)" -C "$(BUSYBOX_SRC_DIR)" --strip-components=1), \
		busybox-extract)
	$(call do_step,PATCH,busybox, \
		$(call with_host_env, \
			if [ ! -f "$(BUSYBOX_PATCH)" ]; then \
				echo "BusyBox patch not found at $(BUSYBOX_PATCH)" >&2; \
				exit 1; \
			fi; \
			patch -d "$(BUSYBOX_SRC_DIR)" -p1 < "$(BUSYBOX_PATCH)"), \
		busybox-patch)
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-verified: $(PROGRESS_DIR)/.busybox-downloaded
	$(call do_verify,busybox,$(ROOT_DIR)/scripts/verify.sh $(BUSYBOX_SHA256) $(BUSYBOX_TAR_PATH),busybox-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-downloaded: | ensure-dirs
	$(call do_download,busybox,$(ROOT_DIR)/scripts/download.sh $(BUSYBOX_URL) $(BUSYBOX_TAR_PATH),busybox-download)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(ROOTFS_DIR) $(LOGS_DIR) $(PROGRESS_DIR) $(BUILDS_DIR)
