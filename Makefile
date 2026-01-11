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

include mk/config.mk
include mk/helpers.mk
include mk/paths.mk

.PHONY: toolchain busybox rootfs clean distclean sanity

toolchain:
	@$(MAKE) -f mk/toolchain.mk TARGET=$(TARGET) toolchain

busybox: toolchain
	@$(MAKE) -f mk/busybox.mk TARGET=$(TARGET) busybox

rootfs: busybox
	@$(MAKE) -f mk/rootfs.mk TARGET=$(TARGET) VERSION=$(VERSION) rootfs

# $(ROOTFS_STAMP): $(BUSYBOX_STAMP) $(SCRIPTS)/create_rootfs_layout.sh config.mk
# 	@sh $(SCRIPTS)/create_rootfs_layout.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(VERSION)"
# 	@touch $@

# $(IMAGE_TARBALL): $(ROOTFS_STAMP) | $(OUTPUT)
# 	@mkdir -p $(OUTPUT)
# 	@sh -c 'chown -R 0:0 "$(ROOTFS)" 2>/dev/null || true'
# 	@tar --numeric-owner --numeric-owner --owner=0 --group=0 -czf $(IMAGE_TARBALL) -C $(ROOTFS) .

# $(OUTPUT):
# 	@mkdir -p $@

clean:
	@rm -rf $(BUILDS_DIR) $(LOGS_DIR) $(ROOTFS) $(IMAGE_TARBALL)

distclean: clean
	@rm -rf $(OUTPUT)

mrproper: distclean
	@rm -rf $(SOURCES_DIR) $(TOOLCHAIN_DIR) $(DOWNLOADS_DIR) $(PROGRESS_DIR)

sanity:
	@true
