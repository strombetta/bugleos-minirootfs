#!/bin/sh
set -eu

ROOTFS=${ROOTFS:-$PWD/build/rootfs}

dirs="bin sbin usr/bin usr/sbin dev proc sys tmp etc var var/run home"
for d in $dirs; do
    if [ ! -d "$ROOTFS/$d" ]; then
        echo "Missing directory $ROOTFS/$d" >&2
        exit 1
    fi
done

for f in passwd group hosts nsswitch.conf wsl.conf; do
    if [ ! -s "$ROOTFS/etc/$f" ]; then
        echo "Missing or empty /etc/$f" >&2
        exit 1
    fi
done

# Check sticky bit on /tmp
mode=$(stat -c %a "$ROOTFS/tmp")
if [ "$mode" != "1777" ]; then
    echo "/tmp permissions are $mode, expected 1777" >&2
    exit 1
fi
