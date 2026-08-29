#!/usr/bin/env bash
# Copy dotfiles from repo to ~/.config (not symlink — per spec).
# Runs in the chroot as root.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

step "Installing dotfiles"

# Find the non-root user we just created (archinstall sets one).
USERNAME=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65000 && $7 ~ /bash|zsh|sh$/ {print $1; exit}')
[[ -z "$USERNAME" ]] && USERNAME=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65000 {print $1; exit}')
[[ -z "$USERNAME" ]] && { step_fail; exit 1; }

HOME_DIR="/home/$USERNAME"
DOT_DIR="$HOME_DIR/.config"
mkdir -p "$DOT_DIR"
chown "$USERNAME:$USERNAME" "$DOT_DIR"

shopt -s dotglob nullglob
for src in "$REPO_ROOT"/dotfiles/*; do
    [[ -d "$src" ]] || continue
    name=$(basename "$src")
    dest="$DOT_DIR/$name"
    mkdir -p "$dest"
    cp -a "$src"/. "$dest"/
    chown -R "$USERNAME:$USERNAME" "$dest"
done
shopt -u dotglob

# System-wide zshenv: point ZDOTDIR at ~/.config/zsh so the .zshrc there
# (copied from dotfiles/zsh/) is what every zsh invocation sources.
install -d -m755 /etc/zsh
cp "$REPO_ROOT/install/zshenv" /etc/zsh/zshenv
chmod 644 /etc/zsh/zshenv

step_ok
