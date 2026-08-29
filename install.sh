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
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) UI_VERBOSE=1 ;;
        --disk=*)      FORCE_DISK="${arg#*=}" ;;
        --disk)        FORCE_DISK="${2:-}"; shift 2 ;;
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
prompt        USERNAME      "Username"
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

ARCH_CFG="$TMP_DIR/archinstall_config.json"
jq \
   --arg disk "$DISK" \
   --arg pw "$USER_PASSWORD" \
   --slurpfile creds "$CREDS" \
   '.["disk-encryption"]["encryption_password"]=$pw | .filesystem.device=$disk' \
   "$REPO_ROOT/archinstall/config.json" > "$ARCH_CFG"

# strip disk-encryption block entirely unless caller asks for it.
if [[ "${ARCHINSTALL_ENCRYPT:-0}" != "1" ]]; then
    jq 'del(.["disk-encryption"])' "$ARCH_CFG" > "$ARCH_CFG.tmp" && mv "$ARCH_CFG.tmp" "$ARCH_CFG"
fi

run "Running archinstall (this can take a while)" \
    archinstall --config "$ARCH_CFG" --creds "$CREDS" --silent

# ---- Phase 3: post-install ---------------------------------------------
step "Post-install"

if ! mountpoint -q /mnt; then
    SUB=$(lsblk -no MOUNTPOINT "$DISK" 2>/dev/null | grep -E '^/mnt' | head -n1)
    if [[ -n "$SUB" && "$SUB" != "/mnt" ]]; then
        mount --bind /mnt "$SUB" 2>/dev/null || true
    fi
    mount "$DISK" /mnt 2>/dev/null || true
fi

run "Running post-install scripts" \
    arch-chroot /mnt /bin/bash "$REPO_ROOT/install/all.sh" \
        "$USERNAME" "$USER_PASSWORD" "$GIT_NAME" "$GIT_EMAIL"

echo
gum style --bold --foreground 10 --align center 'Installation complete!'
echo
gum style --faint --align center "log: $UI_LOG"
gum style --faint --align center "reboot when ready."
echo
