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

$(PROGRESS_DIR)/.rootfs-layout: | ensure-dirs
	$(call do_step,LAYOUT,rootfs, \
		$(call with_host_env, \
			version="$(ROOTFS_VERSION)"; \
			for dir in bin sbin usr/bin usr/sbin dev proc sys tmp etc etc/profile.d var var/run home; do \
				mkdir -p "$(ROOTFS_DIR)/$$dir"; \
			done; \
			chmod 1777 "$(ROOTFS_DIR)/tmp"; \
			printf '%s\n' \
				'root:x:0:0:root:/root:/bin/sh' \
				> "$(ROOTFS_DIR)/etc/passwd"; \
			printf '%s\n' \
				'root:x:0:' \
				> "$(ROOTFS_DIR)/etc/group"; \
			printf '%s\n' \
				'127.0.0.1   localhost' \
				'::1         localhost' \
				> "$(ROOTFS_DIR)/etc/hosts"; \
			printf '%s\n' \
				'passwd: files' \
				'group: files' \
				'shadow: files' \
				'hosts: files dns' \
				> "$(ROOTFS_DIR)/etc/nsswitch.conf"; \
			printf '%s\n' \
				'proc            /proc   proc    defaults                0       0' \
				'sysfs           /sys    sysfs   defaults                0       0' \
				'tmpfs           /tmp    tmpfs   defaults,nosuid,nodev   0       0' \
				> "$(ROOTFS_DIR)/etc/fstab"; \
			printf '%s\n' \
				'::sysinit:/bin/mount -a' \
				'::respawn:/sbin/getty -L ttyS0 115200 vt100' \
				'::ctrlaltdel:/sbin/reboot' \
				> "$(ROOTFS_DIR)/etc/inittab"; \
			printf '%s\n' \
				'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
				'' \
				'if [ -d /etc/profile.d ]; then' \
				'    for script in /etc/profile.d/*.sh; do' \
				'        [ -r "$$script" ] && . "$$script"' \
				'    done' \
				'fi' \
				> "$(ROOTFS_DIR)/etc/profile"; \
			printf '%s\n' \
				'NAME="BugleOS"' \
				'ID=bugleos' \
				"PRETTY_NAME=\"BugleOS v$${version}\"" \
				"VERSION_ID=\"$${version}\"" \
				> "$(ROOTFS_DIR)/etc/os-release"; \
			printf '%s\n' \
				'#!/bin/sh' \
				'[ -t 0 ] || exit 0' \
				'' \
				"printf 'Welcome to BugleOS %s (%s %s %s)\\n' \"$${version}\" \"\\$$(uname -o)\" \"\\$$(uname -r)\" \"\\$$(uname -m)\"" \
				> "$(ROOTFS_DIR)/etc/profile.d/motd.sh"; \
			printf '%s\n' \
				'#!/bin/sh' \
				'PS1='"'"'\e[33m\u@\h\e[0m:\e[96m\w\e[0m \e[35m\\$\e[0m '"'"'' \
				> "$(ROOTFS_DIR)/etc/profile.d/prompt.sh"), \
		rootfs-layout)
	$(Q)touch $@

ensure-dirs:
	@mkdir -p $(ROOTFS_DIR) $(LOGS_DIR) $(PROGRESS_DIR)
