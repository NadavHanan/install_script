# my-arch

Modular Arch Linux bootstrap. Base install via `archinstall`, personal config
via small post-install scripts. Single-orchestrator UX, runs from the ISO.

## Usage

```bash
# from the ISO
curl -sL https://github.com/NadavHanan/install_script/install.sh \
  | INSTALL_REPO=https://github.com/NadavHanan/install_script.git bash

# or from a cloned repo:
./install.sh                       # clean output, logs to /tmp/arch-install-*.log
./install.sh --verbose             # also stream command output to terminal
./install.sh --disk /dev/nvme0n1   # override autodetected disk
ARCHINSTALL_ENCRYPT=1 ./install.sh # opt into LUKS disk encryption
```

## What it does

1. Installs `gum`, `jq`, `archinstall` from the repos (caller is online).
2. Gum UI: username, password, git identity, disk.
3. Runs `archinstall` with `archinstall/config.json` (no LUKS by default; iwd only).
4. Runs `install/all.sh` inside the new system via `arch-chroot`:
   services, mirror ranking, packages, user config, dotfiles, bin scripts,
   post-install README.

The install disk is auto-detected as the single non-removable, non-loopback
block device. If multiple candidates exist, the installer aborts — pass
`--disk` to choose manually (this rewrites `disk_config` in the archinstall
config to match the chosen disk).

## Philosophy

1. fast and minimal
2. apps do one thing and do it well
3. terminal and text files focused system
4. hebrew and RTL support

## Layout

- `install.sh` — interactive orchestrator (runs outside the new install).
- `archinstall/`
  - `config.json` — static install preferences (iwd, pipewire, btrfs, no LUKS).
  - `creds.json`  — user/root password template, filled in by `jq gsub`.
- `install/`
  - `ui.sh`         — gum UI helpers (step, run, prompt, box, heading, …)
  - `disk.sh`       — disk autodetection
  - `all.sh`        — chroot entrypoint
  - `packages.sh`   — pacman install (+ AUR via yay)
  - `reflector.sh`  — rank mirrors post-install
  - `system.sh`     — greetd, fprintd, bluez, cups, udiskie, power-profiles, sshd
  - `user.sh`       — git identity, mimeapps
  - `dotfiles.sh`   — copy `dotfiles/*` into `~/.config/*` + `/etc/zsh/zshenv`
  - `bin.sh`        — copy `bin/*` into `~/.local/bin/`
  - `readme.sh`     — drop `~/POST_INSTALL.md`
  - `greetd.toml`   — copied to `/etc/greetd/config.toml`
  - `mimeapps.list` — copied to `~/.config/mimeapps.list`
  - `zshenv`        — copied to `/etc/zsh/zshenv` (sets `ZDOTDIR`)
  - `POST_INSTALL.md` — copied to `~/POST_INSTALL.md`
- `bin/` — repo commands; copied (executable) into `~/.local/bin/` on setup.
  `setup-backup` configures the optional remote backup later; `install_hebrew_fonts`
  installs Hebrew fonts on demand (the slimmer `install/hebrew-fonts.sh` handles
  it during setup).
- `dotfiles/` — per-tool config; copied into `~/.config/<dir>` on setup.
  `dotfiles/zsh/zshrc` is sourced because `ZDOTDIR` is set in `/etc/zsh/zshenv`.
  The wallpaper binary is intentionally untracked — `install/dotfiles.sh` fetches
  it at install time.

## Replacing a tool

Every user-facing tool is named in **one place**:

| Role           | Where                                |
| -------------- | ------------------------------------ |
| Terminal       | `dotfiles/hypr/hyprland.lua`         |
| File browser   | `dotfiles/hypr/hyprland.lua`         |
| Menu           | `dotfiles/hypr/hyprland.lua`         |
| Browser        | `dotfiles/hypr/hyprland.lua`         |
| Waybar TUIs    | `dotfiles/waybar/config.jsonc`       |
| PDF viewer     | `install/mimeapps.list`              |
| Image viewer   | `install/mimeapps.list`              |
| Text editor    | `install/mimeapps.list`              |
| Password UI    | `bin/passmenu`                       |

Swap one constant, re-run, done.

## Passwords

- `pass` + `pass-otp` for password storage (db created by user).
- `passmenu` (tofi picker → `wl-copy`) is in `bin/` and on `PATH`.
- `fprintd` is auto-enabled and wired into `/etc/pam.d/{greetd,hyprlock,sudo}`
  if a supported fingerprint sensor is detected at install time. See
  `POST_INSTALL.md` for caveats.
