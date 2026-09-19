#!/usr/bin/env bash
# Arch installer. Run from a git clone on the Arch ISO: ./install.sh
set -euo pipefail
# Repo root = dir the script lives in (BASH_SOURCE, not $0, works when sourced/piped).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- deps ---------------------------------------------------------------
pacman -Sy --noconfirm --needed gum jq archinstall
# Shared gum helpers (confirm/prompt/prompt_secret/run/heading) + UI_LOG setup.
source "$REPO_ROOT/install/ui.sh"

clear
confirm "Start installation?" || exit 0

# ---- collect info -------------------------------------------------------
heading "Personal information"
prompt USERNAME "Username"
prompt_secret USER_PASSWORD "User password"
prompt        GIT_NAME   "Git name"
prompt        GIT_EMAIL  "Git email"

heading "Install disk"
# List "PATH SIZE" for real disks, pick one, keep only the path. Empty = user hit Esc.
DISK=$(lsblk -dno PATH,SIZE,TYPE | awk '$3=="disk" {print $1, $2}' | gum choose | awk '{print $1}')
[[ -n "$DISK" ]] || exit 1
confirm "Wipe $DISK and install Arch?" || exit 0

# ---- archinstall --------------------------------------------------------
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Config is static except the disk; patch just that field.
jq --arg disk "$DISK" \
   '.disk_config.device_modifications[0].device = $disk' \
   "$REPO_ROOT/archinstall/config.json" > "$TMP_DIR/config.json"

# "!password" (with !) = literal password key for archinstall.
jq -n \
   --arg user "$USERNAME" --arg pw "$USER_PASSWORD" \
   '{users:[{username:$user, "!password":$pw, sudo:true, groups:[]}],
     "!root-password":$pw, encryption_password:$pw}' \
   > "$TMP_DIR/creds.json"

run "Running archinstall (takes a while)" \
    archinstall --config "$TMP_DIR/config.json" --creds "$TMP_DIR/creds.json" --silent

# ---- post-install -------------------------------------------------------
# archinstall may mount under /mnt/<sub>; bind the deepest /mnt* onto /mnt.
if ! mountpoint -q /mnt; then
    SUB=$(lsblk -no MOUNTPOINT "$DISK" | grep '^/mnt' | awk '{print length, $0}' | sort -n | cut -d' ' -f2- | head -n1)
    mount --bind "$SUB" /mnt
fi
# Bind repo into chroot so all.sh can read its own scripts from inside.
mkdir -p /mnt/root/install_script
mount --bind "$REPO_ROOT" /mnt/root/install_script
run "Post-install scripts" \
    arch-chroot /mnt /bin/bash /root/install_script/install/all.sh "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"
umount /mnt/root/install_script

gum style --bold --foreground 10 --align center 'Installation complete! Reboot when ready.'
