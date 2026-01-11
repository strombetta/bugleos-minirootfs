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

ROOTFS_VERSION ?= $(VERSION)

.PHONY: rootfs ensure-dirs

rootfs: $(PROGRESS_DIR)/.rootfs-done

$(PROGRESS_DIR)/.rootfs-done: $(PROGRESS_DIR)/.rootfs-layout
	$(Q)touch $@

$(PROGRESS_DIR)/.rootfs-layout: $(ROOT_DIR)/scripts/create_rootfs_layout.sh | ensure-dirs
	$(call do_step,LAYOUT,rootfs, \
		$(call with_host_env, \
			sh "$(ROOT_DIR)/scripts/create_rootfs_layout.sh" "$(ROOTFS_DIR)" "$(ROOTFS_VERSION)"), \
		rootfs-layout)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(ROOTFS_DIR) $(LOGS_DIR) $(PROGRESS_DIR)
