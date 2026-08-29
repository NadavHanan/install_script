#!/usr/bin/env bash
# User-level config: git identity, XDG defaults, passmenu wiring.
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

# passmenu via tofi
sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.local/bin"
sudo -u "$USERNAME" cp "$REPO_ROOT/install/passmenu.sh" "$HOME_DIR/.local/bin/passmenu"
sudo -u "$USERNAME" chmod +x "$HOME_DIR/.local/bin/passmenu"

chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.config"
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.local"
step_ok
