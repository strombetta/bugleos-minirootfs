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

# command_not_found_handle is a noop function that prevents printing error messages
# if WSL interop is disabled.
command_not_found_handle() {
  :
}

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
    if [ -z "$username" ]; then
      username="$default_username"
    fi

    case "$username" in
      ""|*[!a-z0-9_-]*)
        echo "Invalid username. A valid username must start with a lowercase letter or underscore, and can contain lowercase letters, digits, underscores, and dashes."
        continue
        ;;
      [a-z_]*)
        ;;
      *)
        echo "Invalid username. A valid username must start with a lowercase letter or underscore, and can contain lowercase letters, digits, underscores, and dashes."
        continue
        ;;
    esac

    if ! adduser -u "$DEFAULT_UID" "$username" >/dev/null 2>&1; then
      echo "Failed to create user '$username'. Please choose a different name."
      continue
    fi

    ok=1
    for g in $DEFAULT_GROUPS; do
      ensure_group "$g" || { ok=0; break; }
      addgroup "$username" "$g" >/dev/null 2>&1 || { ok=0; break; }
    done

    if [ "$ok" -eq 1 ]; then
      break
    fi

    echo "Failed to add '$username' to default groups. Attempting cleanup."
    if command -v deluser >/dev/null 2>&1; then
      deluser "$username" >/dev/null 2>&1 || true
    else
      if [ -f /etc/passwd ]; then
        grep -v "^${username}:" /etc/passwd > /etc/passwd.tmp && mv /etc/passwd.tmp /etc/passwd
      fi
      if [ -f /etc/shadow ]; then
        grep -v "^${username}:" /etc/shadow > /etc/shadow.tmp && mv /etc/shadow.tmp /etc/shadow
      fi
    fi
  done
}

# set_user_as_default sets the given username as the default user in the wsl.conf configuration.
# It will only set it if there is no existing default under the [user] section.
set_user_as_default() {
  username="$1"

  wsl_conf="/etc/wsl.conf"
  touch "$wsl_conf"

  # Append [user] section with default if they don't exist.
  if ! grep -q "^\[user\]" "$wsl_conf"; then
    printf "\n[user]\ndefault=%s\n" "$username" >> "$wsl_conf"
    return
  fi

  # If default is missing from the user section, append it to it.
  if ! sed -n '/^\[user\]/,/^\[/{/^[[:space:]]*default[[:space:]]*=/p}' "$wsl_conf" | grep -q .; then
    sed -i "/^\[user\]/a\\
default=$username" "$wsl_conf"
  fi
}

# powershell_env outputs the contents of PowerShell.exe environment variables $Env:<ARG>
# encoded in UTF-8.
powershell_env() {
  if [ "$#" -ne 1 ]; then
    echo "powershell_env: expected 1 argument, got $# ."
    return 1
  fi
  var="$1"

  ret=$(powershell.exe -NoProfile -Command '& {
                            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
                            $Env:'"$var"'}') 2>/dev/null || true
  # strip control chars like \r and \n
  ret=${ret%%[[:cntrl:]]}
  echo "$ret"
}

echo "Provisioning the new WSL instance $WSL_DISTRO_NAME"
echo "This might take a while..."

# Read the Windows user name.
win_username=$(powershell_env "UserName")
# replace any potential whitespaces with underscores.
win_username=$(printf "%s" "$win_username" | sed 's/ /_/g')

# Check if there is a pre-provisioned users (pre-baked on the rootfs).
user_id=$(get_first_interactive_uid)

# If we don’t have a non system user, let’s create it.
if [ -z "$user_id" ]; then
  create_regular_user "$win_username"

  user_id=$(get_first_interactive_uid)
  if [ -z "$user_id" ]; then
    echo "Failed to create a regular user account"
    exit 1
  fi
fi

# Set the newly created user as the WSL default.
username=$(awk -F: -v uid="$user_id" '($3==uid){print $1; exit}' /etc/passwd)
set_user_as_default "$username"
EOF


icon_base64='AAABAAEAAQEAAAEAIAAwAAAAFgAAACgAAAABAAAAAgAAAAEAIAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//AAAAAA=='
printf '%s' "$icon_base64" | base64 -d > "$rootfs_dir/usr/lib/wsl/bugleos.ico"

chmod 0644 "$rootfs_dir/etc/wsl.conf" "$rootfs_dir/etc/wsl-distribution.conf"
chmod 0755 "$rootfs_dir/etc/oobe.sh"
