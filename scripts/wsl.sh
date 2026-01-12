#!/bin/sh
set -eu

rootfs_dir="${1:?rootfs dir required}"

umask 022

mkdir -p "$rootfs_dir/etc" "$rootfs_dir/usr/lib/wsl"

cat > "$rootfs_dir/etc/wsl.conf" <<'EOF'
[boot]
systemd=false
EOF

cat > "$rootfs_dir/etc/wsl-distribution.conf" <<EOF
[oobe]
defaultUid = 1000
defaultName=bugleos

[shortcut]
enabled=true
icon=/usr/lib/wsl/bugleos.ico

[windowsterminal]
enabled=true
EOF

cat > <<EOF
#!/bin/bash

set -ue

DEFAULT_GROUPS='adm,cdrom,sudo,dip,plugdev'
DEFAULT_UID='1000'

echo 'Please create a default UNIX user account. The username does not need to match your Windows username.'
echo 'For more information visit: https://aka.ms/wslusers'

if getent passwd "$DEFAULT_UID" > /dev/null ; then
  echo 'User account already exists, skipping creation'
  exit 0
fi

while true; do

  # Prompt from the username
  read -p 'Enter new UNIX username: ' username

  # Create the user
  if /usr/sbin/adduser --uid "$DEFAULT_UID" --quiet --gecos ''  "$username"; then

    if /usr/sbin/usermod "$username" -aG "$DEFAULT_GROUPS"; then
      break
    else
      /usr/sbin/deluser "$username"
    fi
  fi
done
EOF

icon_base64='AAABAAEAAQEAAAEAIAAwAAAAFgAAACgAAAABAAAAAgAAAAEAIAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//AAAAAA=='
printf '%s' "$icon_base64" | base64 -d > "$rootfs_dir/usr/lib/wsl/bugleos.ico"

chmod 0644 "$rootfs_dir/etc/wsl.conf" "$rootfs_dir/etc/wsl-distribution.conf"
