#!/usr/bin/env bash
# Runs inside arch-chroot. Args: <username> <git_name> <git_email>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
GIT_NAME="$2"
GIT_EMAIL="$3"

# deploy-ordered: packages first so system.sh's systemctl enables succeed.
substage "installing packages"
bash "$REPO_ROOT/install/packages.sh" "$USERNAME"
substage "system configuration"
bash "$REPO_ROOT/install/system.sh"  "$USERNAME"
substage "ranking mirrors"
bash "$REPO_ROOT/install/reflector.sh"
substage "user defaults"
bash "$REPO_ROOT/install/user.sh"    "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"
substage "dotfiles"
bash "$REPO_ROOT/install/dotfiles.sh" "$USERNAME"
substage "bin scripts"
bash "$REPO_ROOT/install/bin.sh"     "$USERNAME"
# Hebrew fonts need network + curl; both present after packages.sh.
substage "installing Hebrew fonts"
bash "$REPO_ROOT/bin/install_hebrew_fonts"
substage "post-install notes"
bash "$REPO_ROOT/install/readme.sh"  "$USERNAME"
