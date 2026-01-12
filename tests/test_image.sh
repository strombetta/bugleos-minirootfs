#!/bin/sh
set -eu

OUTPUT=${OUTPUT:-$PWD/output}
ARCHITECTURE=${ARCHITECTURE:-$(uname -m)}
VERSION_FILE=${VERSION_FILE:-$OUTPUT/version.env}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

if [ -z "${VERSION:-}" ] && [ -f "$VERSION_FILE" ]; then
    . "$VERSION_FILE"
fi

if [ -z "${VERSION:-}" ] && [ -f "$ROOT_DIR/VERSION" ]; then
    VERSION=$(cat "$ROOT_DIR/VERSION")
fi

VERSION=${VERSION:-1.0.0}
TARBALL="$OUTPUT/bugleos-minirootfs-${VERSION}-${ARCHITECTURE}.tar.gz"

if [ ! -s "$TARBALL" ]; then
    echo "Image tarball missing or empty at $TARBALL" >&2
    exit 1
fi

tar -tzf "$TARBALL" | grep -E '^\./(bin|etc|usr)/' >/dev/null
