#!/usr/bin/env bash
# Runs inside arch-chroot. Args: <username> <git_name> <git_email>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
GIT_NAME="$2"
GIT_EMAIL="$3"

# system.sh first: services, groups, fprintd PAM wiring.
# reflector must rank mirrors BEFORE any package download, then packages
# (which also needs the temporary passwordless sudo it owns for yay).
bash "$REPO_ROOT/install/packages.sh" "$USERNAME"
bash "$REPO_ROOT/install/system.sh"  "$USERNAME"
bash "$REPO_ROOT/install/reflector.sh"
bash "$REPO_ROOT/install/user.sh"    "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"
bash "$REPO_ROOT/install/dotfiles.sh" "$USERNAME"
bash "$REPO_ROOT/install/bin.sh"     "$USERNAME"
bash "$REPO_ROOT/install/readme.sh"  "$USERNAME"

# Optional btrbk backups (opt-in via INSTALL_BTRBK=1).
if [[ "${INSTALL_BTRBK:-0}" == "1" ]]; then
    bash "$REPO_ROOT/install/btrbk.sh"
fi
