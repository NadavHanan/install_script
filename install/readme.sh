#!/usr/bin/env bash
# Drop a short README in the user's home with stack + keybinds + learn-links.
# Args: <username>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"
HOME_DIR="/home/$USERNAME"

step "Writing post-install README"

cp "$REPO_ROOT/install/POST_INSTALL.md" "$HOME_DIR/POST_INSTALL.md"
chown "$USERNAME:$USERNAME" "$HOME_DIR/POST_INSTALL.md"
step_ok
