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
| Terminal     | foot                                       |
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

Local snapshots always run via the `btrbk-backup.timer` as soon as the
prerequisites exist (btrfs on `/`, package `btrbk`). Adding an **off-site**
target is a post-install step — nothing remote is configured during install.
Run:

```sh
setup-backup
```

The wizard
1. scans candidate targets: named SSH hosts (`~/.ssh/config`) and
   mounted/removable btrfs media;
2. asks which to use (SSH server, USB disk, or local-only);
3. verifies the target is reachable/usable (SSH key auth, or USB mounted);
4. shows a summary and asks for confirmation;
5. installs `btrbk`/`rsync`, mounts the pool, writes `/etc/btrbk/btrbk.conf`
   + `backup.env` + the hourly timer, and (for SSH) points a root key at the
   server.

- Retention: **local** 3 daily + 1 weekly + 1 monthly; snapshots live under
  `/mnt/btr_pool/btrbk_snapshots` (thin reflinks — cheap).
- Snapshots of `@` (= `/`) and `@home` are made. `@log` and `@pkg` are
  skipped — journal/pacman-cache snapshots waste space.
- A remote target (btrfs) also applies `target_preserve 3d 1w 3m`.

Inspect: `btrbk list`, `btrbk status`. The log is `/var/log/btrbk.log`, and
no `Persistent=true` is set, so a laptop left closed won't replay a backlog.

### Remote notes

- Backups run only while the target is reachable (home LAN or a plugged-in
  USB disk); the hourly run skips an unreachable target.
- The target must be **btrfs** for snapshot send. A non-btrfs USB target
  still gets the small-config rsync (`/var/lib/iwd`, `/var/lib/bluetooth`,
  `explicit-packages.txt`) but no btrbk send.
- USB btrfs disks won't be auto-mounted by `udiskie`; add an fstab entry or
  mount before running `setup-backup`.

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
