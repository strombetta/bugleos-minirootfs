# Makefile for BugleOS minirootfs

include config.mk

.PHONY: all download binutils gcc-bootstrap kernel-headers musl gcc-final busybox rootfs image test clean distclean

all: image

# Download all sources
SCRIPTS:=scripts
download: | $(SOURCES)
	@sh $(SCRIPTS)/download_sources.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" \
  "$(BINUTILS_VERSION)" "$(GCC_VERSION)" "$(LINUX_VERSION)" "$(MUSL_VERSION)" "$(BUSYBOX_VERSION)"

$(SOURCES):
	@mkdir -p $@

binutils: download
	@sh $(SCRIPTS)/build_binutils.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(BINUTILS_VERSION)"

kernel-headers: download
	@sh $(SCRIPTS)/install_kernel_headers.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(LINUX_VERSION)"

gcc-bootstrap: binutils kernel-headers
	@sh $(SCRIPTS)/build_gcc_bootstrap.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(GCC_VERSION)"

musl: gcc-bootstrap kernel-headers
	@sh $(SCRIPTS)/build_musl.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(MUSL_VERSION)"

gcc-final: musl
	@sh $(SCRIPTS)/build_gcc_final.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(GCC_VERSION)"

busybox: gcc-final
	@sh $(SCRIPTS)/build_busybox.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)" "$(BUSYBOX_VERSION)"

rootfs: busybox
	@sh $(SCRIPTS)/create_rootfs_layout.sh "$(TARGET)" "$(PREFIX)" "$(SYSROOT)" "$(ROOTFS)" "$(SOURCES)" "$(BUILD)"

image: rootfs
	@mkdir -p $(OUTPUT)
	@sh -c 'chown -R 0:0 "$(ROOTFS)" 2>/dev/null || true'
	@tar --numeric-owner -czf $(OUTPUT)/bugleos-minirootfs-wsl.tar.gz -C $(ROOTFS) .

# Testing
TESTS:=tests/test_toolchain.sh tests/test_busybox.sh tests/test_rootfs_layout.sh tests/test_image.sh
test: image
	@set -e; \
	for t in $(TESTS); do \
		echo "Running $$t"; \
		TARGET="$(TARGET)" PREFIX="$(PREFIX)" SYSROOT="$(SYSROOT)" ROOTFS="$(ROOTFS)" OUTPUT="$(OUTPUT)" sh $$t; \
	done

# Cleaning
clean:
	rm -rf $(BUILD)/binutils $(BUILD)/gcc-bootstrap $(BUILD)/gcc-final $(BUILD)/musl $(BUILD)/busybox $(ROOTFS)

# Be careful with distclean; keep sources by default
# Remove toolchain and sysroot as well
distclean: clean
	rm -rf $(PREFIX) $(SYSROOT) $(OUTPUT)/bugleos-minirootfs-wsl.tar.gz

