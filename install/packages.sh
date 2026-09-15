#!/usr/bin/env bash
# Idempotent package install. Runs in the chroot. Arg: <username>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="${1:?usage: packages.sh <username>}"

step "Installing packages"

# Temporary passwordless sudo, needed only for the unattended AUR build below
# (yay/makepkg call sudo themselves). Removed when this script exits.
SUDOERS_FILE="/etc/sudoers.d/90-$USERNAME-nopasswd"
{
    printf '# Temporary: unattended AUR / pacman builds during install.\n'
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USERNAME"
} > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
visudo -c -f "$SUDOERS_FILE" >/dev/null
cleanup() { rm -f "$SUDOERS_FILE"; }
trap cleanup EXIT

PKGS=(
    # base
    base-devel linux-headers openssh curl bluez-utils

    # docs
    man-db man-pages

    # login / compositor
    greetd greetd-tuigreet hyprland hypridle hyprlock
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
    qt5-wayland qt6-wayland
    polkit-gnome
    uwsm

    # status / tray
    waybar mako wob swaybg bluetui wiremix brightnessctl impala
    power-profiles-daemon udiskie libnotify

    # menu / files / viewers
    nautilus gvfs file-roller
    # viewers — zathura needs a PDF plugin or it can't open anything
    zathura zathura-pdf-mupdf imv mpv
    grim slurp wl-clipboard cliphist

    # github tooling
    github-cli xdg-utils

    # xdg + cursor theme
    xdg-user-dirs adwaita-cursors adwaita-icon-theme

    # terminal / shell / editor
    foot zsh zsh-syntax-highlighting zsh-completions fzf tealdeer neovim

    # fonts
    ttf-cascadia-code ttf-font-awesome

    # passwords
    pass pass-otp fprintd

    # nice-to-haves
    tmux btop fastfetch eza ripgrep fd bat typst uv jq libqalculate

    # firmware
    fwupd
)

pacman -Syu --needed --noconfirm "${PKGS[@]}"

# ---- AUR bootstrap: yay from AUR, then AUR packages --------------------
if ! command -v yay >/dev/null; then
    step "Bootstrapping yay from AUR"
    yay_user_home=$(getent passwd "$USERNAME" | cut -d: -f6)
    sudo -u "$USERNAME" bash -c '
        set -e
        work=$(mktemp -d)
        git clone https://aur.archlinux.org/yay-bin.git "$work/yay-bin"
        cd "$work/yay-bin"
        makepkg -si --noconfirm
        cd /
        rm -rf "$work"
    '
fi

# AUR packages
AUR_PKGS=(
    zen-browser-bin
    tofi
    ttf-ms-fonts
)
# tofi is the menu and zen-browser the browser: without these the desktop is
# unusable, so a missing yay is a hard failure, not a silent skip.
if ! command -v yay >/dev/null; then
    step_fail "yay unavailable — AUR packages (${AUR_PKGS[*]}) not installed"
    exit 1
fi
sudo -u "$USERNAME" yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# Run xdg-user-dirs to populate ~/ standard dirs.
sudo -u "$USERNAME" xdg-user-dirs-update || true

step_ok
