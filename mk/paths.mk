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

ROOT_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

BUILDS_DIR ?= $(ROOT_DIR)/builds
DOWNLOADS_DIR ?= $(ROOT_DIR)/downloads
LOGS_DIR ?= $(ROOT_DIR)/logs
OUTPUT_DIR ?= $(ROOT_DIR)/output
SOURCES_DIR ?= $(ROOT_DIR)/sources
TOOLCHAIN_DIR ?= $(ROOT_DIR)/toolchain

BUSYBOX_STAMP :=$(BUILDS_DIR)/.busybox.stamp
DOWNLOAD_STAMP :=$(DOWNLOADS_DIR)/.downloaded
IMAGE_TARBALL :=$(OUTPUT_DIR)/bugleos-minirootfs-$(VERSION)-$(ARCHITECTURE).tar.gz
ROOTFS_STAMP :=$(BUILDS_DIR)/.rootfs.stamp
TOOLCHAIN_STAMP :=$(BUILDS_DIR)/.toolchain.stamp