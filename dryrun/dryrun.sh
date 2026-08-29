#!/usr/bin/env bash
# Safe UI/integration dry-run for the Arch installer.
# No packages, disks, mounts, chroots, or system files are touched.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRYRUN_DIR="$(mktemp -d)"
UI_LOG="$DRYRUN_DIR/install.log"

trap 'rm -rf "$DRYRUN_DIR"' EXIT

# shellcheck source=../install/ui.sh
source "$REPO_ROOT/install/ui.sh"

UI_VERBOSE="${UI_VERBOSE:-0}"

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

fake_command() {
    local name="$1"
    shift
    sleep 1

    printf '[dry-run] %s' "$name"
    if (($#)); then
        printf ' %q' "$@"
    fi
    printf '\n'
}

box() {
    gum style \
        --border rounded \
        --border-foreground 4 \
        --padding "1 3" \
        --width 64 \
        "$@"
}

heading() {
    gum style \
        --bold \
        --foreground 4 \
        "$1"
}

# -------------------------------------------------------------------
# Welcome
# -------------------------------------------------------------------

clear

box \
    "$(gum style --bold --align center 'Arch Linux Setup')" \
    "$(gum style --faint --align center 'Dry run — no system changes will be made')"

echo

if ! gum confirm "Start dry run?"; then
    gum style --foreground 1 "Cancelled."
    exit 0
fi

# -------------------------------------------------------------------
# Personal information
# -------------------------------------------------------------------

heading "Personal information"

prompt USERNAME "Username"
prompt_secret USER_PASSWORD "User password"
prompt GIT_NAME "Git name"
prompt GIT_EMAIL "Git email"

# -------------------------------------------------------------------
# Wi-Fi
# -------------------------------------------------------------------

heading "Wi-Fi"

gum style --faint "Add networks, or leave SSID empty to continue."

WIFI_COUNT=0
WIFI_NAMES=()
WIFI_PASSWORDS=()

while true; do
    SSID=$(gum input --prompt "SSID > ")

    [[ -z "$SSID" ]] && break

    prompt_secret WIFI_PASSWORD "Password for $SSID"

    WIFI_NAMES+=("$SSID")
    WIFI_PASSWORDS+=("$WIFI_PASSWORD")
    ((WIFI_COUNT++))

    gum style --faint "    $SSID"

    if ! gum confirm "Add another network?"; then
        break
    fi
done

gum style --faint "$WIFI_COUNT network(s) configured"

# -------------------------------------------------------------------
# Mirror
# -------------------------------------------------------------------

heading "Mirror"

MIRROR=$(gum input \
    --prompt "Mirror URL > " \
    --value "https://archlinux.org/repos")

# -------------------------------------------------------------------
# Disk
# -------------------------------------------------------------------

heading "Install disk"

DISK="/dev/dry-run"

gum style --faint "Using $DISK"

# -------------------------------------------------------------------
# Password visibility
# -------------------------------------------------------------------

echo

SHOW_PASSWORDS=false

if gum confirm "Show passwords in planned configuration?"; then
    SHOW_PASSWORDS=true
fi

# -------------------------------------------------------------------
# Planned configuration
# -------------------------------------------------------------------

echo

CONFIG=$(
    printf 'User\n\n'
    printf '  Username    %s\n' "$USERNAME"
    printf '  Git name    %s\n' "$GIT_NAME"
    printf '  Git email   %s\n' "$GIT_EMAIL"

    if $SHOW_PASSWORDS; then
        printf '  Password    %s\n' "$USER_PASSWORD"
    fi

    printf '\nSystem\n\n'
    printf '  Disk        %s\n' "$DISK"
    printf '  Mirror      %s\n' "$MIRROR"

    printf '\nWi-Fi\n\n'

    if ((WIFI_COUNT == 0)); then
        printf '  None\n'
    else
        for ((i = 0; i < WIFI_COUNT; i++)); do
            if $SHOW_PASSWORDS; then
                printf '  %-12s %s\n' \
                    "${WIFI_NAMES[$i]}" \
                    "${WIFI_PASSWORDS[$i]}"
            else
                printf '  %s\n' "${WIFI_NAMES[$i]}"
            fi
        done
    fi

    printf '\nPackages\n\n'
    printf '  [configured package list]\n'
)

box "$CONFIG"

echo

if ! gum confirm "Proceed with this configuration?"; then
    gum style --foreground 1 "Installation cancelled."
    exit 0
fi

# -------------------------------------------------------------------
# Installation
# -------------------------------------------------------------------

run "Preparing installation configuration" \
    fake_command \
    "generate-config"

run "Running archinstall" \
    fake_command \
    "archinstall"

run "Configuring system" \
    fake_command \
    "arch-chroot"

run "Installing packages" \
    fake_command \
    "pacman"

run "Installing Google Fonts" \
    fake_command \
    "fonts.sh"

run "Configuring iwd" \
    fake_command \
    "iwd.sh"

run "Installing dotfiles" \
    fake_command \
    "dotfiles.sh"

# -------------------------------------------------------------------
# Complete
# -------------------------------------------------------------------

echo

gum style --bold --foreground 10 --align center 'Installation complete!'

echo

gum style \
    --faint \
    --align center \
    "This was a dry run. No system changes were made."

echo
