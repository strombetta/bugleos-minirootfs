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

TOOLCHAIN_VERSION := 1.0.4
TOOLCHAIN_URL := https://github.com/strombetta/bugleos-make-toolchain/releases/download/v$(TOOLCHAIN_VERSION)/bugleos-toolchain-$(TOOLCHAIN_VERSION)-$(HOST_ARCH).tar.gz
TOOLCHAIN_TAR := bugleos-toolchain-$(TOOLCHAIN_VERSION)-$(HOST_ARCH).tar.gz
TOOLCHAIN_TAR_PATH := $(DOWNLOADS_DIR)/$(TOOLCHAIN_TAR)
TOOLCHAIN_SHA256_aarch64 := 261097c744cbbe501798f380c4a55905165521b4b79f57175ee7bc885a307709
TOOLCHAIN_SHA256_x86_64 := f960df5d1ab73765889d22d6690ab151faa21b01ccb08aa3be708814d1cc4fe0
TOOLCHAIN_SHA256 := $(TOOLCHAIN_SHA256_$(HOST_ARCH))
TOOLCHAIN_DIR ?= $(ROOT_DIR)/toolchain

.PHONY: toolchain	ensure-dirs

toolchain: $(PROGRESS_DIR)/.toolchain-done

$(PROGRESS_DIR)/.toolchain-done: $(PROGRESS_DIR)/.toolchain-unpacked
	$(Q)rm -rf "$(TOOLCHAIN_DIR)"
	$(Q)mkdir -p "$(TOOLCHAIN_DIR)"

	$(call do_step,EXTRACT,toolchain, \
		$(MAKE) -f "$(THIS_MAKEFILE)" unpack-toolchain, \
		toolchain-extract)

	$(Q)touch $@

$(PROGRESS_DIR)/.toolchain-unpacked: $(PROGRESS_DIR)/.toolchain-verified
	@$(TAR) -xf $(TOOLCHAIN_TAR_PATH) -C $(TOOLCHAIN_DIR)
	@touch $@

$(PROGRESS_DIR)/.toolchain-verified: $(PROGRESS_DIR)/.toolchain-downloaded
	$(call do_verify,toolchain,$(ROOT_DIR)/scripts/verify-checksum.sh $(TOOLCHAIN_SHA256) $(TOOLCHAIN_TAR_PATH),toolchain-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.toolchain-downloaded: ensure-dirs
	$(call do_download,toolchain,$(ROOT_DIR)/scripts/download_sources.sh $(TOOLCHAIN_URL) $(TOOLCHAIN_TAR_PATH),toolchain-download)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(TOOLCHAIN_DIR) $(LOGS_DIR) $(PROGRESS_DIR)