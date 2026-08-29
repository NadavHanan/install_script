#!/usr/bin/env bash
# Copy repo bin/ into the user's ~/.local/bin. Per spec: copy, not symlink.
# Args: <username>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
HOME_DIR="/home/$USERNAME"

step "Installing bin scripts"

USER_BIN="$HOME_DIR/.local/bin"
mkdir -p "$USER_BIN"

shopt -s nullglob
for f in "$REPO_ROOT"/bin/*; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f")
    cp "$f" "$USER_BIN/$name"
    chmod +x "$USER_BIN/$name"
done

chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.local"
step_ok
