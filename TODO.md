# Fixed

All items below were fixed (commit/push; DO NOT include in TODO). Status: **done**.

- [#1] `install.sh` now rewrites the real archinstall keys: `disk_config.device_modifications[0].device`
  target, resizes the btrfs root partition to fill the chosen disk, and injects
  `disk_config.disk_encryption` for LUKS. `--disk` and `ARCHINSTALL_ENCRYPT` now actually work.
- [#2] Removed the broken `install/passmenu.sh` copy in `user.sh` (passmenu comes from `bin.sh`).
- [#3] Added `#!/usr/bin/env bash` to `bin/links` and `bin/music`.
- [#4] `bin/music` uses `$HOME/Music` and dropped the `uconv`/`icu` dependency (NFC normalization gone).
- [#5] `bin/links`/*music* guard missing file/dir with a notify + clean exit.
- [#6] Reordered `all.sh`: `reflector.sh` now ranks mirrors **before** `packages.sh`.
- [#7] The permanent `NOPASSWD: ALL` rule is gone from `system.sh`. `packages.sh` creates a temporary
  rule for the AUR build and removes it on exit (`trap cleanup EXIT`).
- [#8] Dropped `USER_PASSWORD` from the `arch-chroot` argv (`all.sh` now takes username, git_name,
  git_email); the password was unused inside the chroot anyway.
- [#9] `packages.sh` and `dotfiles.sh` take `$1 = username` instead of re-deriving it from `/etc/passwd`.
- [#10] Fingerprint probe no longer uses `lsusb` (replaced with a `/sys/bus/usb/devices/*/product` grep),
  so no `usbutils` dependency and it works before packages are installed.
- [#11] AUR installs no longer swallow failures (`|| true` removed).
- [#12] Rewrote `dryrun/dryrun.sh` to match the current flow (services → mirrors → packages → user →
  dotfiles → bin → readme), sourcing `ui.sh` instead of redefining box/heading.
- [#13] Removed stray `.gitkeep`s and the dead `dotfiles/git/` tree.
- [#14] Removed `dotfiles/{hypr,nvim}/.luarc.json` editor artifacts.
- [#15] Dropped the stale marker comment from `install/zshenv`.
- [#16] `all.sh` comment fixed and ordering corrected.
- [#17] Rewrote `install.sh` arg parsing (no more `shift` inside a `for` loop).
- [#18] `prompt_secret` now requires typing the secret twice; username is validated
  (`^[a-z_][a-z0-9_-]*$`) in both `install.sh` and dryrun.
- [#19] `bin/power-profile` strips the marker with `${pick#* }` instead of `awk '{print $2}'`.
- [#20] gh-helper / empty-helper config removed with the `dotfiles/git/` tree.

### Also fixed (found while fixing the above)

- `archinstall/creds.json` had **wrong keys**: it used `name`/`password`/`root_password`, but archinstall
  expects `username`/`!password`/`!root-password`, and there was no `encryption_password` cred for LUKS.
  All three meant the user/root passwords and LUKS password were silently dropped. Template corrected.
- `user.sh` ended with `chown -R .../.local` which errored (dir doesn't exist at that stage) under `set -e`;
  removed (privs handled by `bin.sh`).

### Notes / not fixed (accepted trade-offs)

- `bin/music` dropped Unicode NFC normalization (was `uconv -x any-nfc`). If decomposed filenames are a
  real problem, re-add it and ship `icu`. Skipped: it adds a package dep for an edge case.
- The nopasswd rule is created for the whole AUR section even though only `yay`/`makepkg` need it; scoping
  to `/usr/bin/pacman` alone can break some PKGBUILDs. Current full `ALL` with `trap` removal is the safe
  middle ground.
