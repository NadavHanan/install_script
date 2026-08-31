#!/usr/bin/env bash
# Optional btrbk backup setup. Run inside the chroot during install when
# INSTALL_BTRBK=1. Sets up local snapshots always; remote is opt-in (see
# /etc/btrbk/btrbk.conf + /etc/btrbk/backup.env after install).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

step "Setting up btrbk backups"
pacman -Syu --needed --noconfirm btrbk rsync

# Mount the btrfs pool at its top-level (subvolid=5) so btrbk can reach the
# @ / @home subvolumes and hold the snapshot dir. Mount path applies at boot;
# in the chroot we only write fstab.
mkdir -p /mnt/btr_pool
SRC="$(findmnt -no SOURCE /)"
UUID="$(blkid -s UUID -o value "$SRC")"
if ! grep -q '/mnt/btr_pool' /etc/fstab 2>/dev/null; then
    printf 'UUID=%s  /mnt/btr_pool  btrfs  rw,subvolid=5,compress=zstd  0 0\n' "$UUID" >> /etc/fstab
fi

# Config + runtime driver.
mkdir -p /etc/btrbk
cp "$REPO_ROOT/install/btrbk.conf" /etc/btrbk/btrbk.conf
cp "$REPO_ROOT/install/backup.env" /etc/btrbk/backup.env
cp "$REPO_ROOT/install/backup-run.sh" /usr/local/sbin/backup-run.sh
chmod 755 /usr/local/sbin/backup-run.sh

# Fast ssh timeouts so hourly attempts while off-LAN fail in seconds, not hang.
mkdir -p /root/.ssh
printf 'Host *\n  ConnectTimeout 5\n' > /root/.ssh/config
chmod 600 /root/.ssh/config

# Units + timer.
cp "$REPO_ROOT/install/btrbk-backup.service" /etc/systemd/system/btrbk-backup.service
cp "$REPO_ROOT/install/btrbk-backup.timer"   /etc/systemd/system/btrbk-backup.timer
systemctl enable btrbk-backup.timer

step_ok
