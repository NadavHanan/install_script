#!/usr/bin/env bash
# Install a curated set of Hebrew-compatible Google Fonts during setup.
#
# Uses a git SPARSE clone of google/fonts so only the listed families' font
# blobs are downloaded — not the whole multi-GB repo. Runs in the chroot as
# root (git is provided by packages.sh).
set -euo pipefail

FAMILIES=(heebo notosanshebrew assistant frankruhllibre rubik davidlibre
          notoserifhebrew alef ibmplexsanshebrew miriamlibre arimo
          varelaround tinos bonanova suezone)

dest=/usr/share/fonts/hebrew-google
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# --- clone google/fonts without fetching any blobs yet -------------------
git clone --quiet --depth 1 --filter=blob:none --sparse \
    https://github.com/google/fonts.git "$work/fonts"

# --- pull only the families we want (fetches their font files) -----------
cd "$work/fonts"
sparse_set=()
for f in "${FAMILIES[@]}"; do
    sparse_set+=("ofl/$f")
done
git sparse-checkout set --no-cone "${sparse_set[@]}"

# --- install every font file from those families -------------------------
mkdir -p "$dest"
find "$work/fonts" -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
    -exec install -D -m644 -t "$dest" {} +
fc-cache -f >/dev/null
