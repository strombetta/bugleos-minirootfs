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
command = /etc/oobe.sh
defaultUid = 1000
defaultName=bugleos

[shortcut]
enabled=true
icon=/usr/lib/wsl/bugleos.ico

[windowsterminal]
enabled=true
EOF

cat > "$rootfs_dir/etc/oobe.sh" <<'EOF'
#!/bin/sh
set -eu

DEFAULT_UID=1000
DEFAULT_GROUPS="adm cdrom sudo dip plugdev"

echo "Please create a default UNIX user account. The username does not need to match your Windows username."
echo "For more information visit: https://aka.ms/wslusers"

if awk -F: -v uid="$DEFAULT_UID" '($3==uid){found=1} END{exit(found?0:1)}' /etc/passwd 2>/dev/null; then
  echo "User account (uid=$DEFAULT_UID) already exists, skipping creation"
  exit 0
fi

# Basic username validation: lowercase start, then lowercase/digits/_/-
is_valid_username() {
  case "$1" in
    ""|*[!a-z0-9_-]*)
      return 1
      ;;
  esac
  case "$1" in
    [a-z]*)
      return 0
      ;;
  esac
  return 1
}

# Create group if missing
ensure_group() {
  grp="$1"
  if ! grep -q "^${grp}:" /etc/group 2>/dev/null; then
    addgroup "$grp" >/dev/null 2>&1 || return 1
  fi
  return 0
}

# Rollback user creation in a BusyBox-friendly way (no deluser guaranteed)
rollback_user() {
  u="$1"
  # Remove from passwd/shadow
  if [ -f /etc/passwd ]; then
    grep -v "^${u}:" /etc/passwd > /etc/passwd.tmp && mv /etc/passwd.tmp /etc/passwd
  fi
  if [ -f /etc/shadow ]; then
    grep -v "^${u}:" /etc/shadow > /etc/shadow.tmp && mv /etc/shadow.tmp /etc/shadow
  fi
  # Remove from group/gshadow member lists
  if [ -f /etc/group ]; then
    awk -F: -v u="$u" 'BEGIN{OFS=":"}
      {
        n=split($4,a,","); out=""
        for(i=1;i<=n;i++){ if(a[i] != "" && a[i] != u){ out=(out==""?a[i]:out","a[i]) } }
        $4=out; print
      }' /etc/group > /etc/group.tmp && mv /etc/group.tmp /etc/group
  fi
  if [ -f /etc/gshadow ]; then
    awk -F: -v u="$u" 'BEGIN{OFS=":"}
      {
        n=split($4,a,","); out=""
        for(i=1;i<=n;i++){ if(a[i] != "" && a[i] != u){ out=(out==""?a[i]:out","a[i]) } }
        $4=out; print
      }' /etc/gshadow > /etc/gshadow.tmp && mv /etc/gshadow.tmp /etc/gshadow
  fi
}

while :; do
  printf "Enter new UNIX username: "
  IFS= read -r username

  if ! is_valid_username "$username"; then
    echo "Invalid username. Allowed: lowercase letters, digits, underscore, hyphen; must start with a letter."
    continue
  fi

  if grep -q "^${username}:" /etc/passwd 2>/dev/null; then
    echo "User '$username' already exists. Choose another name."
    continue
  fi

  # Ensure user's primary group exists
  if ! ensure_group "$username"; then
    echo "Failed to create/ensure primary group '$username'."
    continue
  fi

  # BusyBox adduser: commonly
  #   adduser -u UID -G GROUP USER
  # Some builds also support -s SHELL.
  if adduser -u "$DEFAULT_UID" -G "$username" "$username" >/dev/null 2>&1; then
    ok=1
    for g in $DEFAULT_GROUPS; do
      ensure_group "$g" || { ok=0; break; }
      addgroup "$username" "$g" >/dev/null 2>&1 || { ok=0; break; }
    done

    if [ "$ok" -eq 1 ]; then
      echo "User '$username' created with uid=$DEFAULT_UID."
      break
    fi

    echo "Failed to add user to one or more groups; rolling back."
    rollback_user "$username"
  else
    echo "User creation failed; retry."
  fi
done
EOF


icon_base64='AAABAAEAAQEAAAEAIAAwAAAAFgAAACgAAAABAAAAAgAAAAEAIAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//AAAAAA=='
printf '%s' "$icon_base64" | base64 -d > "$rootfs_dir/usr/lib/wsl/bugleos.ico"

chmod 0644 "$rootfs_dir/etc/wsl.conf" "$rootfs_dir/etc/wsl-distribution.conf"
chmod 0755 "$rootfs_dir/etc/oobe.sh"
