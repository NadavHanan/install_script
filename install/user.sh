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

# Bash skel files from useradd are dead weight — zsh is the shell.
rm -f "$HOME_DIR/.bashrc" "$HOME_DIR/.bash_profile" "$HOME_DIR/.bash_logout"

# zsh is the default shell; make sure it's in /etc/shells for chsh.
ZSHPATH="$(command -v zsh)"
if [[ -n "$ZSHPATH" ]]; then
    grep -Fxq "$ZSHPATH" /etc/shells 2>/dev/null || echo "$ZSHPATH" >> /etc/shells
    chsh -s "$ZSHPATH" "$USERNAME"
fi

# Seed the links file used by bin/links (menus -> links). Don't overwrite
# on re-run — it's user data, not config.
LINKS_FILE="$HOME_DIR/Documents/md_files/links"
if [[ ! -f "$LINKS_FILE" ]]; then
    mkdir -p "$(dirname "$LINKS_FILE")"
    printf 'Arch Linux: https://archlinux.org\n' > "$LINKS_FILE"
fi
chown -R "$USERNAME:$USERNAME" "$HOME_DIR/Documents/md_files"

# pass: generate a GPG key and initialise the password store. Skipped on
# re-run if the user already has a secret key for their git email.
if ! sudo -u "$USERNAME" gpg --list-secret-keys --with-colons "$GIT_EMAIL" 2>/dev/null | grep -q '^sec:'; then
    step "Setting up pass (GPG key + password store)"
    prompt_secret KEY_PASSPHRASE "GPG key passphrase (protects your passwords)"
    sudo -u "$USERNAME" gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
        --quick-generate-key "$GIT_NAME <$GIT_EMAIL>" rsa3072 cert 0 <<<"$KEY_PASSPHRASE"
    sudo -u "$USERNAME" gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASSPHRASE" \
        --quick-add-key "$(sudo -u "$USERNAME" gpg --list-secret-keys --with-colons "$GIT_EMAIL" | awk -F: '/^sec:/{print $5; exit}')" rsa3072 encr 0
    unset KEY_PASSPHRASE
    sudo -u "$USERNAME" pass init "$(sudo -u "$USERNAME" gpg --list-secret-keys --with-colons "$GIT_EMAIL" | awk -F: '/^sec:/{print $5; exit}')"
    sudo -u "$USERNAME" pass git init
    # Keep the key passphrase cached for a day so pass doesn't re-prompt.
    GPG_DIR="$HOME_DIR/.gnupg"
    install -d -m700 -o "$USERNAME" -g "$USERNAME" "$GPG_DIR"
    if [[ ! -f "$GPG_DIR/gpg-agent.conf" ]]; then
        printf 'default-cache-ttl 86400\nmax-cache-ttl 86400\n' > "$GPG_DIR/gpg-agent.conf"
        chown "$USERNAME:$USERNAME" "$GPG_DIR/gpg-agent.conf"
    fi
fi

chown -R "$USERNAME:$USERNAME" "$HOME_DIR/.config"
step_ok
