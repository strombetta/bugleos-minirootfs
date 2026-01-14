#!/bin/sh
set -eu

rootfs_dir="${1:?rootfs dir required}"
script_dir=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)

umask 022

mkdir -p "$rootfs_dir/etc" "$rootfs_dir/usr/lib/wsl"

cat > "$rootfs_dir/etc/wsl.conf" <<'EOF'
[boot]
systemd=false

[interop]
enabled=true
appendWindowsPath=false

[automount]
enabled=false
options=metadata,umask=22,fmask=11
EOF

cat > "$rootfs_dir/etc/wsl-distribution.conf" <<EOF
[oobe]
command=/usr/lib/wsl/wsl-oobe.sh
defaultUid=1000
defaultName=BugleOS

[shortcut]
enabled=true
icon=/usr/lib/wsl/bugleos.ico

[windowsterminal]
enabled=true
EOF

cat > "$rootfs_dir/usr/lib/wsl/wsl-oobe.sh" <<'EOF'
#!/bin/sh
set -eu

DEFAULT_UID=1000
DEFAULT_GROUPS="users"

# command_not_found_handle is a noop function that prevents printing error messages
# if WSL interop is disabled.
command_not_found_handle() { :; }

# get_first_interactive_uid returns first interactive non system user uid with uid >=1000.
get_first_interactive_uid() {
  awk -F: '($3 >= 1000) && ($7 !~ /(nologin|false|sync)/) { print $3; exit }' /etc/passwd
}

# Create group if missing.
ensure_group() {
  grp="$1"
  if ! grep -q "^${grp}:" /etc/group 2>/dev/null; then
    addgroup "$grp" >/dev/null 2>&1 || return 1
  fi
  return 0
}

# create_regular_user prompts user for a username and assign default WSL permissions.
# First argument is the prefilled username.
create_regular_user() {
  default_username="$1"

  # Filter the prefilled username to remove invalid characters.
  default_username=$(printf "%s" "$default_username" | sed 's/[^a-z0-9_-]//g')
  # It should start with a character or _.
  default_username=$(printf "%s" "$default_username" | sed 's/^[^a-z_]*//')

  while :; do
    if [ -n "$default_username" ]; then
      printf "Create a default Unix user account [%s]: " "$default_username"
    else
      printf "Create a default Unix user account: "
    fi

    IFS= read -r username
    [ -n "$username" ] || username="$default_username"

    case "$username" in
      ""|*[!a-z0-9_-]*|[^a-z_]*)
        echo "Invalid username. Must start with a lowercase letter or underscore, and contain only lowercase letters, digits, underscores, and dashes."
        continue
        ;;
    esac

    if ! adduser -u "$DEFAULT_UID" -s /bin/sh -h "/home/$username" "$username" >/dev/null 2>&1; then
      echo "Failed to create user '$username'. Please choose a different name."
      continue
    fi

    ok=1
    for g in $DEFAULT_GROUPS; do
      ensure_group "$g" || { ok=0; break; }
      # BusyBox addgroup syntax is: addgroup GROUP [USER]
      addgroup "$username" "$g" >/dev/null 2>&1 || { ok=0; break; }
    done

    [ "$ok" -eq 1 ] && break

    echo "Failed to add '$username' to default groups. Attempting cleanup."
    if command -v deluser >/dev/null 2>&1; then
      deluser "$username" >/dev/null 2>&1 || true
    else
      # Minimal fallback cleanup (best-effort)
      if [ -f /etc/passwd ]; then
        grep -v "^${username}:" /etc/passwd > /etc/passwd.tmp && mv /etc/passwd.tmp /etc/passwd
      fi
      if [ -f /etc/shadow ]; then
        grep -v "^${username}:" /etc/shadow > /etc/shadow.tmp && mv /etc/shadow.tmp /etc/shadow
      fi
      if [ -f /etc/group ]; then
        # remove user from any group members list (best-effort)
        sed "s/\(^[^:]*:[^:]*:[^:]*:\)\(.*\)\b${username}\b,*/\1\2/g; s/,,/,/g; s/,\$//" /etc/group > /etc/group.tmp \
          && mv /etc/group.tmp /etc/group
      fi
    fi
  done
}

# set_user_as_default sets the given username as the default user in the wsl.conf configuration.
# It will only set it if there is no existing default under the [user] section.
set_user_as_default() {
  username="$1"
  wsl_conf="/etc/wsl.conf"
  [ -f "$wsl_conf" ] || : > "$wsl_conf"

  # If no [user] section, append it.
  if ! grep -q '^\[user\]' "$wsl_conf"; then
    printf "\n[user]\ndefault=%s\n" "$username" >> "$wsl_conf"
    return 0
  fi

  # If [user] exists but has no default= inside its section, insert right after [user].
  if ! sed -n '/^\[user\]/,/^\[/{/^[[:space:]]*default[[:space:]]*=/p}' "$wsl_conf" | grep -q .; then
    # BusyBox sed: use a\ to append one line after the match
    sed -i "/^\[user\]/a default=$username" "$wsl_conf"
  fi

  return 0
}

# powershell_env outputs the contents of PowerShell.exe environment variables $Env:<ARG>
# encoded in UTF-8.
powershell_env() {
  [ "$#" -eq 1 ] || { echo "powershell_env: expected 1 argument, got $#." ; return 1; }
  var="$1"

  # If interop is disabled or powershell.exe is missing, this will fail; we swallow it.
  ret=$(
    powershell.exe -NoProfile -Command '& {
      [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
      $Env:'"$var"'
    }' 2>/dev/null || true
  )

  # strip control chars like \r and \n (best-effort)
  ret=${ret%%[[:cntrl:]]}
  echo "$ret"
}

distro_name="${WSL_DISTRO_NAME:-WSL}"

echo "Provisioning the new WSL instance $distro_name"
echo "This might take a while..."

# Read the Windows user name (may be empty if interop disabled)
win_username="$(powershell_env "UserName" || true)"
win_username="$(printf "%s" "$win_username" | sed 's/ /_/g')"

# Check if there is a pre-provisioned user (pre-baked in the rootfs).
user_id="$(get_first_interactive_uid || true)"

# If we don’t have a non system user, let’s create it.
if [ -z "${user_id:-}" ]; then
  create_regular_user "$win_username"

  user_id="$(get_first_interactive_uid || true)"
  if [ -z "${user_id:-}" ]; then
    echo "Failed to create a regular user account"
    exit 1
  fi
fi

# Set the newly created user as the WSL default.
username="$(awk -F: -v uid="$user_id" '($3==uid){print $1; exit}' /etc/passwd)"
set_user_as_default "$username"
EOF

cp "$script_dir/bugleos.ico" "$rootfs_dir/usr/lib/wsl/bugleos.ico"

chmod 0644 "$rootfs_dir/etc/wsl.conf" "$rootfs_dir/etc/wsl-distribution.conf"
chmod 0755 "$rootfs_dir/usr/lib/wsl/wsl-oobe.sh"
