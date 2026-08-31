# Arch Linux — Post-install

You're running a minimal Hyprland setup. Networking is `iwd` only — no
NetworkManager. Here's the lay of the land.

## The stack

| Layer        | Tool                                        |
| ------------ | ------------------------------------------- |
| Compositor   | Hyprland                                    |
| Login        | greetd + tuigreet                           |
| Bar          | waybar                                      |
| Menu         | tofi                                        |
| Notifications| mako                                        |
| Idle/lock    | hypridle + hyprlock                         |
| Audio        | pipewire (wpctl)                            |
| Bluetooth    | bluez + bluetui                             |
| Screenshot   | grim + slurp + wl-copy                      |
| Clipboard    | cliphist + wl-copy                          |
| Files        | nautilus (auto-mount via udiskie)           |
| Power        | power-profiles-daemon                       |
| Browser      | zen-browser                                 |
| Terminal     | kitty                                       |
| Shell        | zsh + fzf (`ZDOTDIR=$HOME/.config/zsh`)     |
| Editor       | nvim                                        |
| PDF / image  | zathura / imv                               |
| Video        | mpv                                         |
| Music        | impala (TUI)                                |
| Printing     | cups + system-config-printer                |
| Passwords    | pass + pass-otp + `passmenu` (tofi)         |

## Key bindings (Hyprland)

- Super+Return — terminal
- Super+D — menu (tofi)
- Super+Alt+Space — system actions (passmenu, music, links, power-profile)
- Super+B — browser
- Super+F — file manager
- Super+1..0 — workspaces
- Super+S — scratchpad terminal
- Super+Ctrl+I — installer
- Print — screenshot region

## Day-to-day

- Audio: `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+`
- Brightness: `brightnessctl set 10%+`
- Bluetooth: `bluetui` (TUI) or `bluetoothctl` on the CLI
- Power profile: `power-profile` (tofi) or `powerprofilesctl set balanced`
- Mount USB / external: `udiskie` is running in the session — just plug in
- Wifi: `impala` (TUI) or `iwctl` directly. Waybar's network module is wired
  to `impala` on click.
- Passwords: `passmenu` — pick an entry, copies to clipboard. `passmenu user`
  copies the login line instead of the password. For 2FA codes, use
  `pass otp <entry>` (provided by `pass-otp`).
- Unlock sudo / greetd / hyprlock: fingerprint via `fprintd` (if a
  supported sensor is present at install time), or type the password.
  Fingerprint unlock does **not** auto-unlock GNOME Keyring or similar
  secret stores — that's a separate `pam_gnome_keyring.so` only triggered
  by password auth.
- Mirrors: re-rank with `sudo reflector --age 12 --latest 20 --sort rate \
  --save /etc/pacman.d/mirrorlist`.

## Backups (btrbk)

Installed only when `INSTALL_BTRBK=1` at install time. A timer
(`btrbk-backup.timer`) takes a local btrfs snapshot every hour and prunes to
retention.

- Retention: **local** 3 daily + 1 weekly + 1 monthly; snapshots live under
  `/mnt/btr_pool/btrbk_snapshots` (thin reflinks — cheap).
- Snapshots of `@` (= `/`) and `@home` are made. `@log` and `@pkg` are
  skipped — journal/pacman-cache snapshots waste space.
- Local snapshots are `systemd`-driven and keep running even with no remote
  target; they protect against accidental edits/deletes, **not** disk
  failure or theft.

Inspect: `btrbk list`, `btrbk status`. The log is `/var/log/btrbk.log`, and
no `Persistent=true` is set, so a laptop left closed won't replay a backlog.

### Remote target (opt-in)

Backups run only when the target is reachable (home LAN or a plugged-in
USB disk). The hourly run simply skips an unreachable target.

1. Pick a transport (SSH server **or** USB disk) and uncomment that block
   under `volume /mnt/btr_pool` in `/etc/btrbk/btrbk.conf`. The target must
   be a **btrfs** filesystem. Remote retention keeps **more** (3 monthly).
   - SSH: set `ssh_uri` + `target` (install `btrbk` on the server).
   - USB: set `target /mnt/backup/btrbk` (mount an btrfs-formatted disk
     there; `udiskie` won't auto-mount a btrfs partition — add an fstab
     entry or use `mount`).
2. In `/etc/btrbk/backup.env`, set:
   - `BACKUP_SSH_HOST=user@host` (for SSH) **or** `BACKUP_USB_DIR=/mnt/backup`
   - `MISC_DEST=` — rsync destination for the small config files. Format:
     SSH `user@host:/path`, USB `/mnt/backup/misc`.
3. For SSH only, install the root SSH key on the server so backups run
   non-interactively:
   ```sh
   sudo ssh-keygen -t ed25519 -N '' -f /root/.ssh/id_ed25519
   sudo ssh-copy-id admin@<server>
   ```
   The server's btrbk target user must also be able to run `btrfs`.

On each hourly run, once reachable, btrbk sends incrementally to the target
and rsyncs `/var/lib/iwd`, `/var/lib/bluetooth`, and
`explicit-packages.txt` (from `pacman -Qqe`) to `MISC_DEST`.

Storage note: local snapshots add a few GB; the remote grows with retained
history — roughly 1.2–2.5x your root+home usage, dominated by the 3-monthly
retention. Drop `target_preserve` (e.g. to `1m`) to shrink it.

## Fingerprint

- fprintd is only enabled and wired into PAM if a supported sensor is
  detected at install time (probed via `lsusb`).
- Some match-on-chip / "smart" sensors (common on newer Dell/HP/Lenovo
  laptops) need a separate AUR driver, or aren't supported by libfprint
  at all. Check `fprintd-list $USER` and the libfprint supported devices
  list before assuming it'll work.
- A bad PAM edit can lock you out of sudo or login entirely. Keep a root
  shell / TTY open while editing `/etc/pam.d/*`. The installer only ever
  inserts one line (`auth sufficient pam_fprintd.so`) before `pam_unix`,
  never replaces existing rules.
- Enroll a finger: `fprintd-enroll $USER`.

## Network

The system uses `iwd` only. After install:

```sh
# scan
iwctl station wlan0 scan

# list
iwctl station wlan0 get-networks

# connect
iwctl station wlan0 connect "<SSID>"
# or non-interactive
iwctl --passphrase "<pass>" station wlan0 connect "<SSID>"
```

Configs land in `/var/lib/iwd/<ssid>.psk` (auto-created on first connect).

## Learn more

- Hyprland: https://wiki.hypr.land/
- Arch wiki: https://wiki.archlinux.org/
- greetd: https://github.com/kennylevinsen/greetd
- PipeWire: https://wiki.archlinux.org/title/PipeWire
- iwd: https://wiki.archlinux.org/title/Iwd
- pass: https://www.passwordstore.org/
- pass-otp: https://github.com/tadfisher/pass-otp
- reflector: https://wiki.archlinux.org/title/Reflector
