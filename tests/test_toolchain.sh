#!/bin/sh
set -eu

PREFIX=${PREFIX:-$PWD/toolchain}
TARGET=${TARGET:-x86_64-linux-musl}

check_bin() {
    if [ ! -x "$1" ]; then
        echo "Missing expected tool: $1" >&2
        exit 1
    fi
}

check_bin "$PREFIX/bin/${TARGET}-gcc"
check_bin "$PREFIX/bin/${TARGET}-ld"
check_bin "$PREFIX/bin/${TARGET}-as"

"$PREFIX/bin/${TARGET}-gcc" --version >/dev/null

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
cat > "$tmpdir/hello.c" <<'EOC'
int main(void){return 0;}
EOC

"$PREFIX/bin/${TARGET}-gcc" -c "$tmpdir/hello.c" -o "$tmpdir/hello.o"
file "$tmpdir/hello.o" | grep -q 'ELF'
