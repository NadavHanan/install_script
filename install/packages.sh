#!/usr/bin/env bash
# Idempotent package install. Runs in the chroot.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

step "Installing packages"

PKGS=(
    # base
    base-devel linux-headers openssh

    # docs
    man-db man-pages

    # login / compositor
    greetd greetd-tuigreet hyprland hypridle hyprlock
    xdg-desktop-portal xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
    polkit-gnome

    # status / tray
    waybar mako wob swaybg bluetui wiremix brightnessctl impala
    power-profiles-daemon udiskie

    # menu / files / viewers
    nautilus file-roller
    zathura imv mpv
    grim slurp wl-clipboard cliphist

    # mirror ranking
    reflector

    # xdg + cursor theme
    xdg-user-dirs adwaita-cursors adwaita-icon-theme

    # terminal / shell
    kitty zsh zsh-syntax-highlighting zsh-completions fzf tealdeer

    # fonts
    ttf-cascadia-code-nerd ttf-font-awesome

    # passwords
    pass pass-otp fprintd

    # nice-to-haves
    tmux btop fastfetch eza ripgrep fd bat typst uv

    # firmware
    fwupd
)

pacman -Syu --needed --noconfirm "${PKGS[@]}"

# ---- AUR bootstrap: yay from AUR, then AUR packages --------------------
USERNAME=$(getent passwd | awk -F: '$3 >= 1000 && $3 < 65000 {print $1; exit}')
[[ -z "$USERNAME" ]] && { step_fail; exit 1; }

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
    tofi-bin
)
if command -v yay >/dev/null; then
    sudo -u "$USERNAME" yay -S --needed --noconfirm "${AUR_PKGS[@]}" || true
fi

# Run xdg-user-dirs to populate ~/ standard dirs.
sudo -u "$USERNAME" xdg-user-dirs-update || true

step_ok
