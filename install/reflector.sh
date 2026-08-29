#!/usr/bin/env bash
# Rank mirrors post-install: top 20 HTTPS mirrors by rate, last 12h sync.
# Runs in the chroot.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=ui.sh
source "$REPO_ROOT/install/ui.sh"

step "Ranking mirrors with reflector"

reflector \
    --protocol https \
    --age 12 \
    --latest 20 \
    --sort rate \
    --save /etc/pacman.d/mirrorlist

step_ok
