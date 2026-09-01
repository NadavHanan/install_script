# TODO

Improvements and fixes for this repo, roughly ordered by impact.

## Bugs (high priority)

- [ ] **Fix hardcoded curl URL.** `install.sh` sets
  `REPO_URL="${INSTALL_REPO:-https://github.com/you/my-arch.git}"`.
  The placeholder `you/my-arch` is wrong — the real remote is
  `NadavHanan/install_script`. Every `curl | bash` run from the README
  would clone a nonexistent repo.
- [ ] **Fix `bin/links` URL mangling.** `cut -d: -f2-` on
  `label:https://example.com` drops the scheme (`https` is field 1 of the
  value, colon-delimited). Split on the *first* colon only instead of `cut`.
  Same class of bug in the label match: `grep "^${picked}:"` treats the
  label as a regex and partial-matches.
- [ ] **Fix screenshot keybind.** `bindings.lua` binds Print to
  `hl.dsp.exec_cmd("grim|slurp|wl-copy")` — a literal string, not a shell
  pipeline. Needs `sh -c 'grim -g "$(slurp)" - | wl-copy'` (or the
  equivalent via the disp dispatcher). As written it launches nothing useful.
- [ ] **Fix `hypridle.conf` lock_cmd precedence.**
  `pidof hyprlock || hyprlock && hyprctl switchxkblayout all 0` parses as
  `pidof hyprlock || (hyprlock && hyprctl ...)` because `&&` binds tighter
  than `||`. If hyprlock is already running, the layout reset is skipped.
  Wrap explicitly.
- [ ] **Fix `$HOME/.bin` vs `~/.local/bin` mismatch.** `bin.sh` installs
  scripts to `~/.local/bin`, but `dotfiles/zsh/zshrc` appends `$HOME/.bin`
  to `PATH`. Scripts won't be resolvable without the shell re-adding the
  right dir. Standardize on one (prefer `~/.local/bin`).
- [ ] **Fix duplicate/divergent Hebrew-font installers.** Two implementations
  exist: `install/hebrew-fonts.sh` (sparse checkout → `/usr/share/fonts/hebrew-google`,
  run during install) and `bin/install_hebrew_fonts` (full tarball → 
  `/usr/share/fonts/truetype/google-fonts/hebrew`, copied to bin but never
  auto-run). README claims both run during setup.
  only the smaller one `install/hebrew-fonts.sh` should run during setup,
  the sacend stay in bin for later use by the user if he wants.
- [ ] **Fix password leak into process list.** `install.sh` passes the
  password via `jq --arg pw "$USER_PASSWORD"`, putting it in argv — visible
  in `ps`/`/proc`. Use `--rawfile` / read from a fd / environment instead.

## Robustness

- [ ] **Add cleanup trap for chroot mounts.** `install.sh` only traps
  `TMP_DIR`. If `archinstall` or a post-install step fails, `/mnt` and the
  `/mnt/root/install_script` bind mount are left mounted. Add an `unmount`
  guard in a `trap`/error path.
- [ ] **De-duplicate the hardcoded partition geometry.** `install.sh`
  hardcodes `ROOT_START=1074790400` and `ESP` size to match `config.json`.
  If the config's sizes change, these silently drift and resize the root
  partition wrong. Derive them from the config where possible, or add a
  comment cross-linking the two constants.
- [ ] **Validate `--disk` argument.** `--disk` with no value silently sets
  `FORCE_DISK=""`. Error out instead.
- [ ] **Reflector ordering.** `reflector.sh` runs early in `all.sh`, but it
  needs network. In the chroot the only networking is `iwd` (not NM), and
  wireless isn't connected yet — the ranking may fail or rank nothing.
  Consider deferring it or falling back gracefully.
- [ ] **Separate root vs user password.** `creds.json` uses `__PASSWORD__`
  for both. A distinct root prompt is safer and standard.

## Neovim config (`dotfiles/nvim`)

- [ ] **Remove the duplicate `nvim-autopairs` entry** in `plugins.lua`.
- [ ] **Drop internal API call.** `require("vim._core.ui2").enable()` in
  `init.lua` reaches into a private nvim module and will break across
  versions.
- [ ] **Reconcile the plugin lock.** `nvim-pack-lock.json` lists
  `plenary.nvim`, `telescope.nvim`, `which-key.nvim`,
  `mason-tool-installer.nvim` that `plugins.lua` never adds — stale entries.
- [ ] **De-duplicate `options.lua`:** `opt.iskeyword:append("-")` is set
  twice, and `vim.diagnostic.config` is called three times (can be one
  merged call).

## Config cleanup

- [ ] **`tofi/config`** has a duplicate `num-results` key (5 then 6).
- [ ] **`tealdeer/config.toml`** ends with an empty `[directories]` section.
- [ ] **`waybar/style.css`** references `#custom-weather`,
  `#custom-update`, `#custom-screenrecording-indicator` that are not in
  `config.jsonc` — dead rules.
- [ ] **`dotfiles/hypr/looknfeel.lua`** has a typo in the comment
  `"fouces browser"` (and the focus-on-title handler may over-focus).
- [ ] **`dotfiles/zsh/zshrc`** runs `compinit` twice (`autoload ... compinit`
  near the top and again after fzf source).

## Repo hygiene

- [ ] **Add `.gitignore`.** At minimum ignore editor/swap files, and decide
  about the committed binary.
- [ ] **Shrink or exclude `dotfiles/hypr/wallpaper.png`.** It's a committed
  binary that bloats every clone; clone from https://github.com/LagrangianLad/arch-minimal-wallpapers/blob/main/wallpapers/hd/kitty.png instead.
- [ ] **Add a `LICENSE`.** Currently unlciensed. use apache-2.0
- [ ] **Add shellcheck to CI.** Files carry `# shellcheck source=` /
  `# shellcheck disable=` comments but nothing runs shellcheck. A minimal
  GitHub Action (or a `make lint` target) over `*.sh` would catch the
  precedence/quoting bugs above.
- [ ] **Pin `archinstall` version.** `config.json` declares
  `"version": "4.4"`, but `install.sh` installs whatever is current; schema
  drift between installed archinstall and the committed config will break
  installs over time. Pin or detect.

## Docs

- [ ] **README "what installs what" drift.** README says both
  `install_hebrew_fonts` and `hebrew-fonts.sh` run during setup, but only
  `hebrew-fonts.sh` does; fix wording.
- [ ] **README curl command** relies on the broken `REPO_URL`; update once
  the URL bug is fixed (or note `INSTALL_REPO` override).
- [ ] **`POST_INSTALL.md`** references `Super+Ctrl+I — installer`, but with no matching binding;
  remove from docs.

## Nice to have

- [ ] **Idempotence guard** at the top of `install.sh`: refuse to run on a
  non-Arch-ISO or when `/mnt` already looks mounted.
- [ ] **UEFI / disk-size preflight checks.** Fail fast with a clear message
  before archinstall if the boot mode isn't UEFI (systemd-boot + UKI) or the
  chosen disk is below the minimum size.
- [ ] **Shell-completion / arg parsing** via `getopts` for the handful of
  flags instead of a hand-rolled loop (cosmetic, not required).
- [ ] **`setup-backup` remote dir path** uses `$TARGET/../configs` — a
  `..` in a config path is fragile; resolve it or drop it.
