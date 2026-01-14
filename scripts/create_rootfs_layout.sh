#!/bin/sh
set -eu

rootfs_dir="${1:?rootfs dir required}"
version="${2:?rootfs version required}"

for dir in bin sbin usr/bin usr/sbin dev proc sys tmp mnt etc etc/profile.d etc/skel var var/run home; do
	mkdir -p "$rootfs_dir/$dir"
done

chmod 1777 "$rootfs_dir/tmp"

cat > "$rootfs_dir/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
EOF

cat > "$rootfs_dir/etc/group" <<'EOF'
root:x:0:
bin:x:1:
daemon:x:2:
tty:x:5:
users:x:100:
EOF

cat > "$rootfs_dir/etc/shadow" <<'EOF'
root:*:0:0:99999:7:::
EOF

chmod 0600 "$rootfs_dir/etc/shadow"

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
tr -d '\\r' < "$rootfs_dir/etc/fstab" > "$rootfs_dir/etc/fstab.tmp"
mv "$rootfs_dir/etc/fstab.tmp" "$rootfs_dir/etc/fstab"

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

cat > "$rootfs_dir/etc/skel/.profile" <<'EOF'
# Source system-wide profile.
if [ -f /etc/profile ]; then
    . /etc/profile
fi

# Load per-user shell config for interactive shells.
export ENV="$HOME/.shrc"
EOF

cat > "$rootfs_dir/etc/skel/.shrc" <<'EOF'
# Only run in interactive shells.
[ -t 0 ] || return 0

if [ -r /etc/profile.d/prompt.sh ]; then
    . /etc/profile.d/prompt.sh
fi
EOF

cat > "$rootfs_dir/etc/os-release" <<EOF
PRETTY_NAME="BugleOS GNUL/Linux"
NAME="BugleOS"
VERSION_ID="$version"
VERSION="$version"
VERSION_CODENAME="BugleOS Core"
ID=bugleos
HOME_URL="https://www.bugleos.com/"
SUPPORT_URL="https://support.bugleos.com/"
BUG_REPORT="https://bugs.bugleos.com/"
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
