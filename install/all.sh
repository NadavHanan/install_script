#!/usr/bin/env bash
# Runs inside arch-chroot. Args: <username> <password> <git_name> <git_email>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
USER_PASSWORD="$2"
GIT_NAME="$3"
GIT_EMAIL="$4"

# system.sh runs first: services, groups, passwordless sudo (needed for yay),
# and the fprintd PAM wiring.
bash "$REPO_ROOT/install/system.sh"  "$USERNAME"
bash "$REPO_ROOT/install/packages.sh"
bash "$REPO_ROOT/install/reflector.sh"
bash "$REPO_ROOT/install/user.sh"    "$USERNAME" "$GIT_NAME" "$GIT_EMAIL"
bash "$REPO_ROOT/install/dotfiles.sh"
bash "$REPO_ROOT/install/bin.sh"     "$USERNAME"
bash "$REPO_ROOT/install/readme.sh"  "$USERNAME"
