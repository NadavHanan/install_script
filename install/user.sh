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

# Write git's global config to the XDG location (~/.config/git/config) instead
# of the legacy ~/.gitconfig. `--file` targets that exact path deterministically
# (git's --global+XGD_CONFIG_HOME behaviour is version-dependent).
GIT_CFG="$HOME_DIR/.config/git/config"
# Create the dir owned by the user, otherwise git (run as them) can't write
# its .lock file into a root-owned directory.
install -d -o "$USERNAME" -g "$USERNAME" "$(dirname "$GIT_CFG")"
sudo -u "$USERNAME" git config --file "$GIT_CFG" user.name  "$GIT_NAME"
sudo -u "$USERNAME" git config --file "$GIT_CFG" user.email "$GIT_EMAIL"
sudo -u "$USERNAME" git config --file "$GIT_CFG" init.defaultBranch master
sudo -u "$USERNAME" git config --file "$GIT_CFG" pull.rebase true

# Use the GitHub CLI as git's credential helper for HTTPS remotes, so git
# pushes/pulls via https authenticate with `gh` (run `gh auth login` once).
sudo -u "$USERNAME" git config --file "$GIT_CFG" credential."https://github.com".helper "!/usr/bin/gh auth git-credential"
sudo -u "$USERNAME" git config --file "$GIT_CFG" credential."https://gist.github.com".helper "!/usr/bin/gh auth git-credential"

# zsh is the default shell; make sure it's in /etc/shells for chsh.
ZSHPATH="$(command -v zsh)"
if [[ -n "$ZSHPATH" ]]; then
    grep -Fxq "$ZSHPATH" /etc/shells 2>/dev/null || echo "$ZSHPATH" >> /etc/shells
    chsh -s "$ZSHPATH" "$USERNAME"
fi

# passmenu is handled by bin.sh (copies bin/passmenu).
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.config"
step_ok
