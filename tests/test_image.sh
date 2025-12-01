#!/bin/sh
set -eu

OUTPUT=${OUTPUT:-$PWD/output}
TARBALL="$OUTPUT/bugleos-minirootfs-wsl.tar.gz"

if [ ! -s "$TARBALL" ]; then
    echo "Image tarball missing or empty at $TARBALL" >&2
    exit 1
fi

tar -tzf "$TARBALL" | grep -E '^\./(bin|etc|usr)/' >/dev/null
