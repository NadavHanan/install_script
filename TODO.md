# TODO

Ideas, roughly in priority order. Everything here is optional — the installer
works without any of it.

## Testing

- [ ] **Test VM harness.** A script that boots the ISO in qemu with a scratch
  disk and runs `install.sh --disk /dev/vda` end to end (pre-seeded answers,
  see unattended mode below). Highest value item on this list — everything
  else is currently verified by hand-wiping real disks.
- [ ] **CI: `bash -n` + shellcheck + `jq empty`.** The repo has no
  `.github/workflows` at all. A tiny workflow running shellcheck over
  `install.sh install/*.sh bin/*` and `jq empty` over the JSONs would catch
  most regressions in this repo's failure class.

## Robustness

- [ ] **Pin or hard-fail on archinstall schema.** The version warning in
  `install.sh` is easy to miss on an ISO. Fail hard when the major version
  differs (the config schema breaks between majors), or document a pinned
  `archinstall` package for the ISO.
- [ ] **Network preflight.** The script assumes online but only finds out when
  pacman fails. A cheap `curl -fsSI archlinux.org` before phase 2 with a
  readable error would help.
- [ ] **Shred temp creds.** `TMP_DIR` (plaintext passwords) is `rm -rf`'d on
  exit; consider `shred -u` on the password files for parity with the care
  taken keeping them out of argv.

## UX

- [ ] **`--yes` / unattended mode.** Pre-seed username/git identity from flags
  or env so re-running the installer on a test VM is scriptable (pairs with
  the qemu harness above).

## Desktop wiring (ideas, not bugs)

- [ ] **cliphist history keeps secrets.** `passmenu-tofi` now wipes both
  clipboard selections after 45s, but the cliphist DB still holds the blobs
  until they age out. Proper fix: filter in the cliphist-store watcher.
- [ ] **Night light.** `wlsunset` (tiny, terminal-focused) with a
  hypridle/autostart line — Hyprland has no built-in.
- [ ] **TUI border color.** TUIs carry the `TUI` app-id tag; a `bordercolor`
  windowrule on `class:TUI` in looknfeel.lua would color-code them.

## Cool stuff

- [ ] **`yazi`** — TUI file manager. Nautilus exists, but the philosophy is
  terminal-first; a real one is faster for bulk moves and `~/.config` dives.
- [ ] **`zoxide`** — smart `cd` that remembers paths (`z proj`). Tiny, one
  line in `.zshrc`, huge QoL in a terminal-focused workflow.
- [ ] **`glow`** — render markdown in the terminal. `~/Documents/md_files`
  (links, notes) is already a thing; glow makes it readable without a GUI.
- [ ] **`swappy`** — annotate + share screenshots. Currently `grim | wl-copy`
  dumps a raw image; swappy opens an editor where you can draw/highlight,
  then copy or save.
- [ ] **`cava`** — terminal audio visualizer for waybar-adjacent showing off.
  Purely cosmetic, zero utility, very cool.
- [ ] **Wallpaper cycler.** `bin/wallpaper` — pick a random wallpaper from a
  dir and hand it to `swaybg` (or swap to `swww` for crossfade). Pair with a
  `menus` entry or a hypridle timer.
- [ ] **Media keys.** XF86AudioPlay/Next/Prev are unbound; `playerctl` +
  three binds in `bindings.lua` if wanted.
- [ ] **Tealdeer cache.** `tealdeer update` (best-effort) at the end of
  `install/all.sh` so `tldr` works on first boot.

## Maybe-never

- [ ] `ttf-ms-fonts` (AUR) is pulled for unclear reasons; verify it's needed
  or drop it (license, size).
- [ ] Hebrew locale: Hyprland keyboard layout (`us,il`) and fonts are covered;
  if RTL text rendering ever needs `he_IL.UTF-8`, add it to `locale_config`
  in `archinstall/config.json`.
- [ ] Wallpaper: the kitty.png fetch is a hard-coded third-party URL; consider
  committing a small wallpaper to the repo instead so the install has one
  fewer network dependency.
