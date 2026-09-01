#!/usr/bin/env bash
# Rank mirrors post-install: top 20 HTTPS mirrors by rate, last 12h sync.
# Runs in the chroot.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

step "Ranking mirrors with reflector"

# Best-effort: on a first boot the chroot's network (iwd) may not be up yet,
# so don't let a failed ranking abort the rest of the setup.
ranks=$(reflector --protocol https --age 12 --latest 20 --sort rate 2>/dev/null) \
    || true
if [[ -z "$ranks" ]]; then
    gum style --faint "    reflector returned nothing (no network yet) — keeping default mirrorlist"
else
    printf '%s\n' "$ranks" > /etc/pacman.d/mirrorlist
fi

step_ok
