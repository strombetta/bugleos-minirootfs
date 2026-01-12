#!/bin/sh
set -eu

rootfs_dir="${1:?rootfs dir required}"
version="${2:?rootfs version required}"

for dir in bin sbin usr/bin usr/sbin dev proc sys tmp etc etc/profile.d var var/run home; do
	mkdir -p "$rootfs_dir/$dir"
done

chmod 1777 "$rootfs_dir/tmp"

cat > "$rootfs_dir/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
EOF

cat > "$rootfs_dir/etc/group" <<'EOF'
root:x:0:
EOF

cat > "$rootfs_dir/etc/hosts" <<'EOF'
127.0.0.1   localhost
::1         localhost
EOF

cat > "$rootfs_dir/etc/nsswitch.conf" <<'EOF'
passwd: files
group: files
shadow: files
hosts: files dns
EOF

cat > "$rootfs_dir/etc/fstab" <<'EOF'
proc            /proc   proc    defaults                0       0
sysfs           /sys    sysfs   defaults                0       0
tmpfs           /tmp    tmpfs   defaults,nosuid,nodev   0       0
EOF

cat > "$rootfs_dir/etc/inittab" <<'EOF'
::sysinit:/bin/mount -a
::respawn:/sbin/getty -L ttyS0 115200 vt100
::ctrlaltdel:/sbin/reboot
EOF

cat > "$rootfs_dir/etc/profile" <<'EOF'
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

if [ -d /etc/profile.d ]; then
    for script in /etc/profile.d/*.sh; do
        [ -r "$script" ] && . "$script"
    done
fi
EOF

cat > "$rootfs_dir/etc/os-release" <<EOF
NAME="BugleOS"
ID=bugleos
PRETTY_NAME="BugleOS v$version"
VERSION_ID="$version"
EOF

cat > "$rootfs_dir/etc/profile.d/motd.sh" <<EOF
#!/bin/sh
[ -t 0 ] || exit 0

printf 'Welcome to BugleOS %s (%s %s %s)\n' "$version" "\$(uname -o)" "\$(uname -r)" "\$(uname -m)"
EOF

cat > "$rootfs_dir/etc/profile.d/prompt.sh" <<'EOF'
#!/bin/sh
PS1='\e[33m\u@\h\e[0m:\e[96m\w\e[0m \e[35m\$\e[0m '
EOF
