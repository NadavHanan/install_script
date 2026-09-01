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
    REPO_URL="${INSTALL_REPO:-https://github.com/NadavHanan/install_script.git}"
    REPO_ROOT="/tmp/my-arch"
    [[ -d "$REPO_ROOT" ]] || git clone --depth 1 "$REPO_URL" "$REPO_ROOT"
fi

TMP_DIR="$(mktemp -d)"
UI_LOG="${UI_LOG:-/tmp/arch-install-$(date +%Y%m%d-%H%M%S).log}"
export UI_LOG

# Best-effort unmount of whatever this run binds into the chroot, then drop
# temp files. Never fatal on cleanup.
BOUND_SUB=""
cleanup() {
    umount -q /mnt/root/install_script 2>/dev/null
    [[ -n "$BOUND_SUB" ]] && umount -q /mnt 2>/dev/null
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# ---- Args ----------------------------------------------------------------
# Map long (--verbose / --disk[=]) flags to short getopts form, validating as
# we go, then let getopts handle combining/ordering.
UI_VERBOSE=0
FORCE_DISK=""
ARGS=()
while (($#)); do
    case "$1" in
        --verbose) ARGS+=(-v); shift ;;
        --disk)    if (($# > 1)); then ARGS+=(-d "$2"); shift 2; else
                       echo "install.sh: --disk requires an argument" >&2; exit 2; fi ;;
        --disk=*)  ARGS+=(-d "${1#--disk=}"); shift ;;
        -v|-d)     ARGS+=("$1"); shift ;;
        *)         echo "install.sh: unrecognized option: $1" >&2; exit 2 ;;
    esac
done
set -- "${ARGS[@]}"
while getopts "vd:" opt; do
    case "$opt" in
        v) UI_VERBOSE=1 ;;
        d) FORCE_DISK="$OPTARG" ;;
        *) echo "usage: install.sh [--verbose] [--disk /dev/xxx]" >&2; exit 2 ;;
    esac
done
export UI_VERBOSE

# ---- Preflight ------------------------------------------------------------
# Must be a live Arch env, booted in EFI (systemd-boot + UKI), with nothing
# already mounted at /mnt. Refuse early instead of a half-done install.
[[ -f /etc/arch-release ]] || {
    echo "install.sh: not an Arch environment (no /etc/arch-release)" >&2; exit 1; }
[[ -d /sys/firmware/efi ]] || {
    echo "install.sh: boot mode is not UEFI; systemd-boot/UKI needs EFI" >&2; exit 1; }
mountpoint -q /mnt && {
    echo "install.sh: /mnt is already mounted; refusing to overwrite" >&2; exit 1; }

# ---- Phase 1: install gum/jq/archinstall --------------------------------
# Caller is responsible for having an internet connection.
need() { command -v "$1" >/dev/null 2>&1 || return 1; }

if ! need gum || ! need jq || ! need archinstall; then
    echo "==> installing gum, jq, archinstall"
    pacman -Sy --noconfirm --needed gum jq archinstall
fi

# Warn if the installed archinstall schema differs from our committed config
# (keep "version" in archinstall/config.json in sync).
EXPECT_SCHEMA=$(jq -r '.version // empty' "$REPO_ROOT/archinstall/config.json" 2>/dev/null)
HAVE_VERSION=$(archinstall --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -n1)
if [[ -n "$EXPECT_SCHEMA" && -n "$HAVE_VERSION" && "$HAVE_VERSION" != "$EXPECT_SCHEMA" ]]; then
    echo ":: warning: archinstall $HAVE_VERSION != config schema $EXPECT_SCHEMA;" \
         "pin the version or update archinstall/config.json" >&2
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
prompt_secret ROOT_PASSWORD "Root password"
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
# Read secrets from files so they never appear in this process's argv (ps).
printf '%s' "$USER_PASSWORD" > "$TMP_DIR/userpw"
printf '%s' "$ROOT_PASSWORD" > "$TMP_DIR/rootpw"
jq \
   --arg user "$USERNAME" \
   --rawfile pw "$TMP_DIR/userpw" \
   --rawfile rpw "$TMP_DIR/rootpw" \
   'walk(
      if type == "string"
      then gsub("__USER__"; $user)
           | gsub("__PASSWORD__"; $pw)
           | gsub("__ROOT_PASSWORD__"; $rpw)
      else .
      end
    )' \
   "$REPO_ROOT/archinstall/creds.json" > "$CREDS"

# archinstall schema: disk lives under disk_config, encryption is nested as
# disk_config.disk_encryption, and the encryption password is a top-level
# creds key (encryption_password) that archinstall merges in.
# Resize the btrfs root partition to fill the chosen disk, not the fixed 29GiB.
# ROOT_START = boot partition's `start` (1 MiB) + its `size` (1 GiB ESP) from
# archinstall/config.json — keep the numbers in sync with that file.
DISK_SIZE=$(lsblk -bdno SIZE "$DISK") || { step_fail "could not stat $DISK"; exit 1; }
ROOT_START=1074790400    # 1 MiB offset + 1 GiB ESP (see archinstall/config.json)
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
        BOUND_SUB="$SUB"
    fi
fi
mountpoint -q /mnt || { echo "/mnt is not a valid mountpoint; aborting" >&2; exit 1; }

mkdir -p /mnt/root/install_script
mount --bind "$REPO_ROOT" /mnt/root/install_script

if ! run "Running post-install scripts" \
        arch-chroot /mnt /bin/bash /root/install_script/install/all.sh \
            "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"; then
    step_fail
    exit 1
fi

umount /mnt/root/install_script

echo
gum style --bold --foreground 10 --align center 'Installation complete!'
echo
gum style --faint --align center "log: $UI_LOG"
gum style --faint --align center "reboot when ready."
echo
