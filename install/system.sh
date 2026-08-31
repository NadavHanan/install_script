#!/usr/bin/env bash
# System-wide config archinstall doesn't already do.
# Runs in the chroot. Arg: <username>
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

USERNAME="$1"

step "Enabling services"

systemctl enable greetd.service
systemctl enable iwd.service
systemctl enable bluetooth.service
systemctl enable cups.socket
systemctl enable power-profiles-daemon.service
systemctl enable udiskie.service
systemctl enable sshd.service
systemctl enable fstrim.timer

# greetd -> tuigreet -> Hyprland
mkdir -p /etc/greetd
cp "$REPO_ROOT/install/greetd.toml" /etc/greetd/config.toml
chmod 644 /etc/greetd/config.toml
id greeter &>/dev/null || useradd -r -d /var/empty -s /usr/sbin/nologin greeter

# ---- User group memberships ---------------------------------------------
# archinstall only adds wheel. Hyprland, printers, input devices need more.
step "Adding $USERNAME to video, input, lp, audio, bluetooth"
for grp in video input lp audio bluetooth; do
    getent group "$grp" >/dev/null || groupadd "$grp"
    usermod -aG "$grp" "$USERNAME"
done

# ---- fprintd: only enable + wire PAM if a supported sensor is present ---
# libfprint only supports a subset of readers; some match-on-chip sensors
# (common on newer Dell/HP/Lenovo) need extra AUR drivers or are unsupported.
# We probe via lsusb. If nothing shows up, we leave fprintd disabled and
# PAM untouched.

has_fingerprint_sensor() {
    # headless probe via /sys — no usbutils dependency.
    shopt -s nullglob
    grep -hiE 'finger|goodix|synaptics.*(fingerprint|finger)|elan.*(fingerprint|finger)|validity|authentec' \
        /sys/bus/usb/devices/*/product 2>/dev/null | grep -q .
}

if has_fingerprint_sensor; then
    step "Fingerprint sensor detected, enabling fprintd"
    systemctl enable fprintd.service

    # Add pam_fprintd.so as sufficient before pam_unix for greetd, hyprlock,
    # and sudo. A bad PAM edit can lock the user out, so we keep this narrow:
    # we never delete or replace existing rules, only insert one line.
    for pamfile in /etc/pam.d/greetd /etc/pam.d/hyprlock /etc/pam.d/sudo; do
        [[ -f "$pamfile" ]] || continue
        if grep -q "pam_fprintd.so" "$pamfile"; then
            continue
        fi
        if grep -q "^auth.*pam_unix.so" "$pamfile"; then
            sed -i '0,/^auth.*pam_unix.so/s//auth        sufficient    pam_fprintd.so\n&/' "$pamfile"
        else
            printf '\nauth        sufficient    pam_fprintd.so\n' >> "$pamfile"
        fi
    done

    # Note: fingerprint unlock does NOT auto-unlock GNOME Keyring / secret
    # stores. pam_gnome_keyring.so is the separate piece for that, and it
    # only fires on password auth. We don't add it here because there's no
    # GNOME Keyring setup yet.
else
    gum style --faint "    no fingerprint sensor detected — fprintd left disabled"
fi

step_ok
