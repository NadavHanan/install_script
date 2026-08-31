#!/usr/bin/env bash
# UI/integration dry-run for the Arch installer. No packages, disks, mounts,
# chroots, or system files are touched.
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRYRUN_DIR="$(mktemp -d)"
UI_LOG="$DRYRUN_DIR/install.log"
export UI_VERBOSE="${UI_VERBOSE:-0}"

trap 'rm -rf "$DRYRUN_DIR"' EXIT

# shellcheck source=../install/ui.sh
source "$REPO_ROOT/install/ui.sh"

fake_command() {
    local name="$1"
    shift
    sleep 1
    printf '[dry-run] %s' "$name"
    (($#)) && printf ' %q' "$@"
    printf '\n'
}

clear

box \
    "$(gum style --bold --align center 'Arch Linux Setup')" \
    "$(gum style --faint --align center 'Dry run — no system changes will be made')"

echo

gum confirm "Start dry run?" || { gum style --foreground 1 "Cancelled."; exit 0; }

heading "Personal information"
while true; do
    prompt USERNAME "Username"
    [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] && break
    gum style --foreground 1 "invalid username: lowercase letters, digits, - and _ only"
done
prompt_secret USER_PASSWORD "User password"
prompt GIT_NAME "Git name"
prompt GIT_EMAIL "Git email"

heading "Install disk"
DISK="/dev/dry-run"
gum style --faint "    using $DISK"

echo
CONFIG=$(
    printf 'User\n\n'
    printf '  Username    %s\n' "$USERNAME"
    printf '  Git name    %s\n' "$GIT_NAME"
    printf '  Git email   %s\n' "$GIT_EMAIL"
    printf '\nSystem\n\n'
    printf '  Disk        %s\n' "$DISK"
)
box "$CONFIG"

echo

gum confirm "Proceed with this configuration?" || { gum style --foreground 1 "Installation cancelled."; exit 0; }

run "System services / groups" fake_command system
run "Ranking mirrors"          fake_command reflector
run "Installing packages"      fake_command pacman
run "User config"              fake_command user
run "Installing dotfiles"      fake_command dotfiles
run "Installing bin scripts"   fake_command bin
run "Post-install README"      fake_command readme

echo

gum style --bold --foreground 10 --align center 'Installation complete!'

echo
gum style --faint --align center 'This was a dry run. No system changes were made.'
echo
