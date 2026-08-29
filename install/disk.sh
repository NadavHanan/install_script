#!/usr/bin/env bash
# Disk autodetection for the installer.
# Picks the first non-removable, non-loopback block device with nonzero size.
# Aborts (exit 1) if the candidate set is ambiguous or empty.
set -euo pipefail

candidates=$(lsblk -dnpo NAME,RM,TYPE,SIZE 2>/dev/null \
    | awk '$2==0 && $3=="disk" && $4!="0B" {print $1}')

if [[ -z "$candidates" ]]; then
    echo "no non-removable disks found" >&2
    exit 1
fi

count=$(printf '%s\n' "$candidates" | wc -l)
if [[ "$count" -gt 1 ]]; then
    echo "ambiguous install disk; candidates:" >&2
    printf '%s\n' "$candidates" >&2
    echo "pass --disk /dev/xxx to choose manually" >&2
    exit 1
fi

printf '%s' "$candidates"
