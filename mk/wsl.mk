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
WSL_RECIPE_SCRIPT := $(ROOT_DIR)/scripts/wsl.sh

.PHONY: wsl ensure-dirs

wsl: $(WSL_TARBALL)

$(WSL_TARBALL): $(PROGRESS_DIR)/.rootfs-wsl
	@mkdir -p $(OUTPUT_DIR)
	@sh -c 'chown -R 0:0 "$(ROOTFS_DIR)" 2>/dev/null || true'
	@$(TAR) --numeric-owner --owner=0 --group=0 -czf $(WSL_TARBALL) -C $(ROOTFS_DIR) .

$(PROGRESS_DIR)/.rootfs-wsl: $(PROGRESS_DIR)/.rootfs-done $(WSL_RECIPE_SCRIPT) | ensure-dirs
	$(call do_step,RECIPE,wsl, \
		$(call with_host_env, \
			sh "$(WSL_RECIPE_SCRIPT)" "$(ROOTFS_DIR)" "$(ROOTFS_VERSION)"), \
		rootfs-wsl)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(ROOTFS_DIR) $(LOGS_DIR) $(PROGRESS_DIR)
