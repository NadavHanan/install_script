#!/usr/bin/env bash
# Arch bootstrap installer orchestrator.
# Usage: curl ... | bash
#        ./install.sh
#        ./install.sh --verbose
#        ./install.sh --disk /dev/nvme0n1
#
# Runs from an Arch ISO. Assumes the network is already up.
# Three phases:
#   1. install gum/jq/archinstall
#   2. gum UI: collect info, plan, run archinstall
#   3. chroot post-install
set -u

# Resolve repo root whether we're run from disk, piped, or curl-fetched.
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    REPO_URL="${INSTALL_REPO:-https://github.com/you/my-arch.git}"
    REPO_ROOT="/tmp/my-arch"
    [[ -d "$REPO_ROOT" ]] || git clone --depth 1 "$REPO_URL" "$REPO_ROOT"
fi

TMP_DIR="$(mktemp -d)"
UI_LOG="${UI_LOG:-/tmp/arch-install-$(date +%Y%m%d-%H%M%S).log}"
export UI_LOG
trap 'rm -rf "$TMP_DIR"' EXIT

# ---- Args ----------------------------------------------------------------
UI_VERBOSE=0
FORCE_DISK=""
while (($#)); do
    case "$1" in
        -v|--verbose) UI_VERBOSE=1; shift ;;
        --disk=*)      FORCE_DISK="${1#*=}"; shift ;;
        --disk)        FORCE_DISK="${2:-}"; shift 2 ;;
        *)             shift ;;
    esac
done
export UI_VERBOSE

# ---- Phase 1: install gum/jq/archinstall --------------------------------
# Caller is responsible for having an internet connection.
need() { command -v "$1" >/dev/null 2>&1 || return 1; }

if ! need gum || ! need jq || ! need archinstall; then
    echo "==> installing gum, jq, archinstall"
    pacman -Sy --noconfirm --needed gum jq archinstall
fi

# ---- Phase 2: gum UI -----------------------------------------------------
# shellcheck source=install/ui.sh
source "$REPO_ROOT/install/ui.sh"

clear

box \
    "$(gum style --bold --align center 'Arch Linux Setup')" \
    "$(gum style --faint --align center 'Bootstrap + post-install configuration')"

echo

if ! confirm "Start installation?"; then
    gum style --foreground 1 "Cancelled."
    exit 0
fi

heading "Personal information"
while true; do
    prompt USERNAME "Username"
    [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] && break
    gum style --foreground 1 "invalid username: lowercase letters, digits, - and _ only"
done
prompt_secret USER_PASSWORD "User password"
prompt        GIT_NAME      "Git name"
prompt        GIT_EMAIL     "Git email"

heading "Install disk"
if [[ -n "$FORCE_DISK" ]]; then
    DISK="$FORCE_DISK"
else
    DISK=$(bash "$REPO_ROOT/install/disk.sh") || { step_fail; exit 1; }
fi
gum style --faint "    using $DISK"

echo
if ! confirm "Proceed with this disk ($DISK)?"; then
    gum style --foreground 1 "Cancelled."
    exit 0
fi

# ---- Phase 2b: archinstall ----------------------------------------------
step "Building archinstall config"

CREDS="$TMP_DIR/creds.json"
jq \
   --arg user "$USERNAME" \
   --arg pw "$USER_PASSWORD" \
   'walk(
      if type == "string"
      then gsub("__USER__"; $user) | gsub("__PASSWORD__"; $pw)
      else .
      end
    )' \
   "$REPO_ROOT/archinstall/creds.json" > "$CREDS"

# archinstall schema: disk lives under disk_config, encryption is nested as
# disk_config.disk_encryption, and the encryption password is a top-level
# creds key (encryption_password) that archinstall merges in.
# Resize the btrfs root partition to fill the chosen disk, not the fixed 29GiB.
DISK_SIZE=$(lsblk -bdno SIZE "$DISK") || { step_fail "could not stat $DISK"; exit 1; }
ROOT_START=1074790400    # boot: 1 MiB offset + 1 GiB ESP
GPT_RESERVE=1048576      # 1 MiB backup GPT header
ROOT_SIZE=$((DISK_SIZE - ROOT_START - GPT_RESERVE))
if (( ROOT_SIZE <= 0 )); then
    step_fail "disk too small for 1 GiB ESP + root" >&2
    exit 1
fi

ARCH_CFG="$TMP_DIR/archinstall_config.json"
jq \
   --arg disk "$DISK" \
   --argjson size "$ROOT_SIZE" \
   '.disk_config.device_modifications[0].device=$disk |
    .disk_config.device_modifications[0].partitions[1].size.value=$size' \
   "$REPO_ROOT/archinstall/config.json" > "$ARCH_CFG"

# opt into LUKS: add disk_encryption inside disk_config, encrypting the root
# partition (obj_id from archinstall/config.json). Password flows via creds.
if [[ "${ARCHINSTALL_ENCRYPT:-0}" == "1" ]]; then
    jq '.disk_config.disk_encryption={
            encryption_type:"luks",
            partitions:["670f10e9-70ef-403d-b253-cf228d8740d0"],
            iter_time:2000
        }' "$ARCH_CFG" > "$ARCH_CFG.tmp" && mv "$ARCH_CFG.tmp" "$ARCH_CFG"
fi

substage "archinstall: partitioning + base install (takes a while)"
run "Running archinstall" \
    archinstall --config "$ARCH_CFG" --creds "$CREDS" --silent

# ---- Phase 3: post-install ---------------------------------------------
step "Post-install"

if ! mountpoint -q /mnt; then
    SUB=$(lsblk -no MOUNTPOINT "$DISK" 2>/dev/null \
        | grep -E '^/mnt' \
        | awk '{ print length, $0 }' | sort -n | cut -d' ' -f2- \
        | head -n1)
    if [[ -z "$SUB" ]]; then
        step_fail "could not find archinstall mountpoint under /mnt for $DISK" >&2
        exit 1
    fi
    if [[ "$SUB" != "/mnt" ]]; then
        mount --bind "$SUB" /mnt
    fi
fi
mountpoint -q /mnt || { echo "/mnt is not a valid mountpoint; aborting" >&2; exit 1; }

mkdir -p /mnt/root/install_script
mount --bind "$REPO_ROOT" /mnt/root/install_script

run "Running post-install scripts" \
    arch-chroot /mnt /bin/bash /root/install_script/install/all.sh \
        "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"

umount /mnt/root/install_script

echo
gum style --bold --foreground 10 --align center 'Installation complete!'
echo
gum style --faint --align center "log: $UI_LOG"
gum style --faint --align center "reboot when ready."
echo
