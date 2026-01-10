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

TOOLCHAIN_VERSION := 1.0.5
TOOLCHAIN_URL := https://github.com/strombetta/bugleos-make-toolchain/releases/download/v$(TOOLCHAIN_VERSION)/bugleos-toolchain-$(TOOLCHAIN_VERSION)-$(HOST_ARCH).tar.gz
TOOLCHAIN_TAR := bugleos-toolchain-$(TOOLCHAIN_VERSION)-$(HOST_ARCH).tar.gz
TOOLCHAIN_TAR_PATH := $(DOWNLOADS_DIR)/$(TOOLCHAIN_TAR)
TOOLCHAIN_SHA256_aarch64 := 7d77534599614b92424f01aa7b970e45e5a7b6b60384c17e0b2599ad8440df32
TOOLCHAIN_SHA256_x86_64 := e7cc369ed44dbe1dbb0678ed0bb0f90e23d7c78ca50aaa9d4eb14b56a8d5ba27
TOOLCHAIN_SHA256 := $(TOOLCHAIN_SHA256_$(HOST_ARCH))

.PHONY: toolchain	ensure-dirs

toolchain: $(PROGRESS_DIR)/.toolchain-done

$(PROGRESS_DIR)/.toolchain-done: $(PROGRESS_DIR)/.toolchain-unpacked
	$(Q)touch $@

$(PROGRESS_DIR)/.toolchain-unpacked: $(PROGRESS_DIR)/.toolchain-verified
	$(call do_unpack,toolchain,$(ROOT_DIR)/scripts/unpack.sh $(TOOLCHAIN_TAR_PATH) $(TOOLCHAIN_DIR),toolchain-unpack)
	$(Q)touch $@

$(PROGRESS_DIR)/.toolchain-verified: $(PROGRESS_DIR)/.toolchain-downloaded
	$(call do_verify,toolchain,$(ROOT_DIR)/scripts/verify.sh $(TOOLCHAIN_SHA256) $(TOOLCHAIN_TAR_PATH),toolchain-verify)
	$(Q)touch $@

$(PROGRESS_DIR)/.toolchain-downloaded: | ensure-dirs
	$(call do_download,toolchain,$(ROOT_DIR)/scripts/download.sh $(TOOLCHAIN_URL) $(TOOLCHAIN_TAR_PATH),toolchain-download)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(DOWNLOADS_DIR) $(TOOLCHAIN_DIR) $(LOGS_DIR) $(PROGRESS_DIR)