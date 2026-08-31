#!/usr/bin/env bash
# User-level config: git identity, XDG defaults.
# Args: <username> <git_name> <git_email>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
GIT_NAME="$2"
GIT_EMAIL="$3"
HOME_DIR="/home/$USERNAME"

step "Configuring user defaults"

mkdir -p "$HOME_DIR/.config"
cp "$REPO_ROOT/install/mimeapps.list" "$HOME_DIR/.config/mimeapps.list"

sudo -u "$USERNAME" git config --global user.name  "$GIT_NAME"
sudo -u "$USERNAME" git config --global user.email "$GIT_EMAIL"
sudo -u "$USERNAME" git config --global init.defaultBranch master
sudo -u "$USERNAME" git config --global pull.rebase true

# passmenu is handled by bin.sh (copies bin/passmenu).
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.config"
step_ok
