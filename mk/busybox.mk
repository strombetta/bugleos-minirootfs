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

.PHONY: busybox ensure-dirs

busybox: $(PROGRESS_DIR)/.busybox-done

$(PROGRESS_DIR)/.busybox-done: $(PROGRESS_DIR)/.busybox-built
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-built: $(PROGRESS_DIR)/.busybox-unpacked
	$(call do_step,BUILD,busybox,$(ROOT_DIR)/scripts/build_busybox.sh "$(TARGET)" "$(TOOLCHAIN_DIR)" "$(TOOLCHAIN_DIR)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(BUSYBOX_VERSION)",busybox-build)
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-unpacked: $(PROGRESS_DIR)/.busybox-verified
	$(call do_unpack,busybox,$(ROOT_DIR)/scripts/unpack.sh $(BUSYBOX_TAR_PATH) $(DOWNLOADS_DIR),busybox-unpack)
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-verified: $(PROGRESS_DIR)/.busybox-downloaded
	$(call do_verify,busybox,$(ROOT_DIR)/scripts/verify.sh $(BUSYBOX_SHA256) $(BUSYBOX_TAR_PATH),busybox-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.busybox-downloaded: | ensure-dirs
	$(call do_download,busybox,$(ROOT_DIR)/scripts/download_sources.sh $(BUSYBOX_URL) $(BUSYBOX_TAR_PATH),busybox-download)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(ROOTFS_DIR) $(LOGS_DIR) $(PROGRESS_DIR) $(BUILDS_DIR)