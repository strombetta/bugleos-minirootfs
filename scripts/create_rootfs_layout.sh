#!/bin/sh
set -eu

# create_rootfs_layout.sh TARGET PREFIX SYSROOT ROOTFS SOURCES BUILD
TARGET=$1
PREFIX=$2
SYSROOT=$3
ROOTFS=$4
SOURCES=$5
BUILD=$6

# Create directory structure
for dir in bin sbin usr/bin usr/sbin dev proc sys tmp etc var var/run home; do
    mkdir -p "$ROOTFS/$dir"
done
chmod 1777 "$ROOTFS/tmp"

# Basic /etc files
cat > "$ROOTFS/etc/passwd" <<'EOP'
root:x:0:0:root:/root:/bin/sh
EOP

cat > "$ROOTFS/etc/group" <<'EOG'
root:x:0:
EOG

cat > "$ROOTFS/etc/hosts" <<'EOH'
127.0.0.1   localhost
::1         localhost
EOH

cat > "$ROOTFS/etc/nsswitch.conf" <<'EON'
passwd: files
group: files
shadow: files
hosts: files dns
EON

cat > "$ROOTFS/etc/profile" <<'EOPR'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PS1='[\u@bugleos \W]$ '
EOPR

cat > "$ROOTFS/etc/wsl.conf" <<'EOW'
[interop]
appendWindowsPath = false

[automount]
options = "metadata"
EOW
