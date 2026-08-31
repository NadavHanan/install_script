#!/usr/bin/env bash
# Hourly backup driver. Installed to /usr/local/sbin/backup-run.sh.
#  - btrbk: local snapshots always; remote incremental send when target up.
#  - rsync: small config files (/var/lib/iwd, /var/lib/bluetooth, pacman -Qe)
#           to the remote/USB target when it is reachable.
set -uo pipefail

POOL=/mnt/btr_pool
SNAPDIR="$POOL/btrbk_snapshots"

if ! mountpoint -q "$POOL"; then
    echo "btr_pool not mounted; skipping backup (will retry next hour)"
    exit 0
fi
mkdir -p "$SNAPDIR"

btrbk run
rc=$?

# ---- small config files, only when a remote/USB target is reachable ------
source /etc/btrbk/backup.env
avail=0
if [[ -n "${BACKUP_SSH_HOST:-}" ]] && ssh -q -o BatchMode=yes -o ConnectTimeout=4 "${BACKUP_SSH_HOST}" true 2>/dev/null; then
    avail=1
fi
if [[ -n "${BACKUP_USB_DIR:-}" ]] && mountpoint -q "${BACKUP_USB_DIR}"; then
    avail=1
fi

if (( avail )) && [[ -n "${MISC_DEST:-}" ]]; then
    stage=$(mktemp -d)
    pacman -Qqe > "$stage/explicit-packages.txt" 2>/dev/null || true
    for d in /var/lib/iwd /var/lib/bluetooth; do
        [[ -d "$d" ]] && cp -a "$d" "$stage/$(basename "$d")"
    done
    rsync -a "$stage/" "$MISC_DEST/" 2>/dev/null || echo "misc rsync failed"
    rm -rf "$stage"
fi

exit "$rc"
