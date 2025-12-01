#!/bin/sh
set -eu

ROOTFS=${ROOTFS:-$PWD/build/rootfs}

if [ ! -x "$ROOTFS/bin/busybox" ]; then
    echo "BusyBox binary missing at $ROOTFS/bin/busybox" >&2
    exit 1
fi

file "$ROOTFS/bin/busybox" | grep -q 'ELF'
file "$ROOTFS/bin/busybox" | grep -qi 'statically linked'

# Optional runtime check
if "$ROOTFS/bin/busybox" --help >/dev/null 2>&1; then
    echo "BusyBox help executed"
else
    echo "BusyBox not executable on this host (expected in cross scenario)"
fi
