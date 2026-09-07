#!/usr/bin/env bash
# Runs inside arch-chroot. Args: <username> <git_name> <git_email>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
GIT_NAME="$2"
GIT_EMAIL="$3"

# deploy-ordered: mirrors first so the big pacman install uses ranked
# mirrors; packages before system.sh so its systemctl enables succeed.
substage "ranking mirrors"
bash "$REPO_ROOT/install/reflector.sh"
substage "installing packages"
bash "$REPO_ROOT/install/packages.sh" "$USERNAME"
substage "system configuration"
bash "$REPO_ROOT/install/system.sh"  "$USERNAME"
substage "user defaults"
bash "$REPO_ROOT/install/user.sh"    "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"
substage "dotfiles"
bash "$REPO_ROOT/install/dotfiles.sh" "$USERNAME"
substage "bin scripts"
bash "$REPO_ROOT/install/bin.sh"     "$USERNAME"
substage "installing Hebrew fonts"
# Best-effort like the wallpaper fetch: needs network, and a missing font
# set shouldn't abort an otherwise complete install.
bash "$REPO_ROOT/bin/install_hebrew_fonts" \
    || gum style --faint "    font install failed (offline?) — run install_hebrew_fonts later"
substage "post-install notes"
bash "$REPO_ROOT/install/readme.sh"  "$USERNAME"
