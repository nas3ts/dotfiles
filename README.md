# dotfiles

My Hyprland-based desktop environment dotfiles. Includes Hyprland window manager config, Zsh shell setup with Aliae alias management, waybar status bar, dunst notifications, and various terminal app configs.

## Installation

### 1. Clone the repository

```bash
git clone --recurse-submodules https://github.com/nas3ts/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

> This clones both the main repo and the terminal themes submodule (stored in `themes/terminal/`).

### 2. Run install

```bash
./install.sh
```

This interactive script:
- Checks and links config directories in `~/.config/`
- Handles conflicts — existing configs are listed and you can choose which to back up to `~/.config/.backup/` and link from dotfiles
- Links themes to `~/.config/omarchy/themes/`
- Requires `gum` (install via `yay -S gum` if missing)

### 3. Link Zsh config

```bash
ln -s ~/.dotfiles/.zshrc ~/.zshrc
ln -s ~/.dotfiles/.zsh ~/.zsh
```

### 4. Update submodules later

```bash
git pull --recurse-submodules
git submodule update --remote
```

Or use the `gupdate` alias (defined in `~/.dotfiles/.aliae/core.yml`):
```bash
gupdate
```

---

## Configuration

The install script handles symlinking config directories. Re-run it anytime to relink:

```bash
./install.sh
```

### What install does

1. **Links configs** — Scans `configs/` and symlinks dirs into `~/.config/`
   - **Conflicts** (existing files/dirs): listed with numbers — pick which to back up to `~/.config/.backup/` and symlink
2. **Links themes** — Scans `themes/omarchy/` and symlinks into `~/.config/omarchy/themes/`

### Configs

Every directory in `configs/` is symlinked to `~/.config/<name>`:

| Dir | App | Configures |
|-----|-----|------------|
| `git/` | Git | Aliases, diff algorithm, pull/push behavior, rerere, user identity |
| `hypr/` | Hyprland | WM settings, keybindings, autostart, monitors, input, idle/lock, window rules, XDPH, night light |
| `waybar/` | Waybar | Status bar modules (workspaces, music, clock, weather, network, battery, tray, tailscale, caffeine/dnd indicators) |
| `dunst/` | Dunst | Notification daemon appearance and behavior |
| `kitty/` | Kitty | Terminal emulator font, colors, layout, keybindings |
| `walker/` | Walker | Application launcher providers, prefixes, custom Kuroi theme |
| `yazi/` | Yazi | File manager keymap, theme, 7 plugins, catppuccin-mocha flavor |
| `superfile/` | Superfile | File manager config, hotkeys, custom Kuroi theme |
| `mpv/` | mpv | Video player — GPU decode, profiles, 14 Lua scripts (sponsorblock, modernx OSC, autolyrics, thumbfast, etc.) |
| `zellij/` | Zellij | Terminal multiplexer layout and keybindings |
| `rmpc/` | rmpc | MPD client layout, album art, tabs |
| `swayosd/` | SwayOSD | On-screen display for volume/brightness, custom CSS |
| `managarr/` | Managarr | Radarr/Sonarr host and API config |
| `glow/` | Glow | Markdown renderer style and pager width |
| `.mako/` | Mako | Notification daemon colors, font, border radius |
| `.aliae.yml` | Aliae | Aggregator pointing to `.aliae/` files |
| `mimeapps.list` | System | Default apps (nvim for text, mpv for video, zen-browser for http, imv for images, zathura for PDF) |

### Restore backups

If you backed up existing configs during install (they go to `~/.config/.backup/`), restore them with:

```bash
./restore.sh
```

Lists all backups with numbers — pick which to restore. The script removes the symlink and moves the backup back to its original location.

### Manual configuration

Some config values are personal and require manual editing:

#### Config files

These files contain settings you may want to adjust manually:

| File | What to change |
|------|----------------|
| `configs/git/config` | `user.name` and `user.email` if you use different credentials |
| `configs/hypr/envs.conf` | Cursor theme (`XCURSOR_THEME`), cursor size, display scale (`GDK_SCALE`) |
| `configs/hypr/monitors.conf` | Monitor resolution, position, and scale. See [Hyprland wiki](https://wiki.hyprland.org/Configuring/Monitors/) for syntax |

---

## Architecture

### Config flow

```
configs/                  ← Source templates
     ↓  (symlinks)
~/.config/                ← Where apps read configs
     ↓
Hyprland, waybar, etc.    ← Apps running on the desktop
```

### Hyprland layers

Hyprland loads configs in this order (defined in `~/.config/hypr/hyprland.conf`):

1. **Omarchy defaults** — `~/.local/share/omarchy/default/hypr/` — base config from the DE framework
2. **Theme overrides** — `~/.config/omarchy/current/theme/hyprland.conf` — theme-specific settings
3. **User overrides** — `~/.config/hypr/` — your personal settings (envs, bindings, autostart, etc.)

Files in `~/.config/hypr/` (user overrides) take precedence over omarchy defaults. The omarchy defaults are not meant to be edited directly — override what you need in the user layer instead.

### Shell setup

Files in `~/.dotfiles/`:

| File | Purpose |
|------|---------|
| `.zshrc` | Main Zsh config — auto-installs tools on first run, sets history opts, vi mode keybinds, env vars |
| `.zsh/plugins.zsh` | Zinit plugin loader — `zsh-autosuggestions`, `zsh-syntax-highlighting` with custom highlight styles |
| `.zsh/inits.zsh` | Shell init — `eval "$(aliae init)"`, `eval "$(zoxide init zsh)"`, oh-my-posh prompt, fzf, completion config |
| `.zsh/functions.zsh` | Personal functions — `ytm` (YouTube MP3), `qti`/`qui` (qBittorrent TUI) |
| `.aliae/` | Alias manager — organized by domain (see below) |

**Key environment variables** set in `.zshrc`:
`ALIAE_CONFIG`, `OMP_CONFIG`, `GOPROXY`, `SUDO_PROMPT`, `TMPDIR`

**Zsh keybindings**: vi mode (`bindkey -v`), `^W`/`^S` for history search, `^E` opens yazi widget, `^J` opens jfsh widget

**Aliae** — Alias manager. Configs in `.aliae/` are organized by domain and aggregated via `~/.dotfiles/configs/.aliae.yml`:

| File | Covers |
|------|--------|
| `core.yml` | Shell shortcuts (`c`=clear, `v`=nvim, `x`=exit), yay aliases, `ff`=fastfetch, `top`=btop, `dsks`=lsblk |
| `git.yml` | `gupdate` (pull+submodules), 30+ `*ignore` aliases for gitignore templates |
| `ls.yml` | 25+ lsd aliases — `l`, `la`, `ll`, tree (`lt`), `lr`, `ld`, `lk`, `lz`, `ldot` |
| `nav.yml` | `..`/`...`/`....`/`.....` dir nav, `dot`/`dev`/`doc`/`vid`/`pic`/`dow`/`des`/`mus` quick-jumps |
| `omarchy.yml` | `oai` (AUR install), `ou` (update), `ot` (theme), `hr` (hyprctl reload), `orw` (restart waybar), etc. |
| `path.yml` | Adds `~/.dotfiles/scripts`, `~/bin`, `~/go/bin`, `~/.cargo/bin` to PATH |
| `scripts.yml` | Aliases for scripts in `scripts/` |
| `completions/zsh` | Shell completions for the `aliae` command |

---

## Scripts

Scripts in `scripts/` are added to PATH via `configs/hypr/envs.conf`. Each is standalone and can be called from anywhere.

| Script | What it does |
|--------|-------------|
| `hypr-reload` | Runs `hyprctl reload` and sends a desktop notification with the result |
| `dnd-toggle` | Toggles dunst do-not-disturb mode on/off |
| `caffeine-toggle` | Toggles hypridle (prevents screen sleep) on/off |
| `waybar-toggle` | Hides/shows waybar and adjusts window gaps accordingly |
| `workspace-osd` | Listens on Hyprland socket and shows workspace changes via dunstify |
| `virtmon-toggle` | Creates a headless monitor + starts wayvnc VNC server for remote access |
| `playlist-gen` | Generates mpv playlist from directory |

### Script details

**`playlist-gen`** - Generates an m3u8 playlist from a directory of audio files.
```bash
playlist-gen /path/to/music  # outputs playlist.m3u8 in current directory
```

**`workspace-osd`** - Background daemon that listens on the Hyprland socket and shows workspace switch notifications via dunstify.

**Waybar indicators** (`configs/waybar/indicators/`) — Shell scripts used by waybar modules:

| Indicator | Shows |
|-----------|-------|
| `music.sh` | Current MPD track via rmpc — click to launch rmpc, right-click play/pause |
| `caffeine.sh` | Caffeine (hypridle) on/off status |
| `dnd.sh` | Do-not-disturb on/off status |

---

## Troubleshooting

### Scripts not found after startup

If custom scripts work after manually running `hyprctl reload` but not at session start, the issue is PATH resolution at startup. The `envs.conf` sets PATH correctly for Hyprland context, but the initial session environment may differ.

Fix: Your scripts use `$DOTFILES_DIR/scripts/script-name` in bindings (not bare script names). As long as `envs.conf` is sourced before `bindings.conf` (it is, by default), this should work.

### Config not reloading

Run `hyprctl reload` from a terminal — if it works there but not via the binding, check that the script path in `bindings.conf` is correct. If it fails entirely, check `hyprctl clients` to see if Hyprland is running and `journalctl --user -xeu hyprland` for errors.

### Symlinks broken after repo move

If you move the dotfiles repo, update the symlinks in `~/.config/` to point to the new location:
```bash
rm ~/.config/hypr && ln -s ~/.dotfiles/configs/hypr ~/.config/hypr
```

### Re-run install

To relink configs (e.g. after a fresh clone):

```bash
./install.sh
```

### Edit personal config

To update qBittorrent credentials:

```bash
nano ~/.dotfiles/.zsh/functions.zsh
```

Then reload your shell: `exec zsh`

---

## Themes

This repo includes the **Kuroi** theme for omarchy:

| Component | Location |
|-----------|----------|
| omarchy theme | `themes/omarchy/kuroi/` — colors, backgrounds, cursor/icons theme, Neovim colorscheme, Walker launcher CSS |
| opencode theme | `themes/opencode/kuroi.json` — syntax highlighting, markdown, diff colors |
| terminal themes | `themes/terminal/` — git submodule, terminal emulator colorschemes |

---

## Prerequisites

These tools are required for the desktop environment to work. Most are auto-installed by `.zshrc` on first run, but install manually if needed.

| Tool | Purpose |
|------|---------|
| [Hyprland](https://hyprland.org/) | Wayland compositor / window manager |
| [uwsm](https://github.com/Vladimir-csp/uwsm) | Wayland session manager |
| [waybar](https://github.com/Alexays/Waybar) | Status bar |
| [dunst](https://github.com/dunst-project/dunst) / [mako](https://github.com/emersion/mako) | Notification daemon |
| [hypridle](https://github.com/hyprland/hypridle) | Idle management |
| [hyprlock](https://github.com/hyprland/hyprlock) | Screen locker |
| [hyprsunset](https://github.com/hyprland/hyprsunset) | Blue light filter / night light |
| [omarchy](https://github.com/jL城外/omarchy) | Desktop environment framework |
| [fcitx5](https://fcitx-im.org/) | Input method |
| [Alacritty](https://alacritty.org/) / [Kitty](https://sw.kovidgoyal.net/kitty/) / [Ghostty](https://ghostty.org/) | Terminal emulator |
| [yazi](https://github.com/sxyazi/yazi) / [superfile](https://github.com/MHNightCat/superfile) | Terminal file managers |
| [zellij](https://zellij.dev/) | Terminal multiplexer |
| [mpv](https://mpv.io/) | Video player (+ [SponsorBlock](https://github.com/po5/mpv_sponsorblock) script) |
| [rmpc](https://github.com/weirdraworld/rmpc) | MPD client |
| [swayosd](https://github.com/ErikReider/SwayOSD) | On-screen display |
| [walker](https://github.com/abenz1267/walker) | Application launcher |
| [glow](https://github.com/charmbracelet/glow) | Markdown renderer |
| [jfsh](https://github.com/ApexAllMonitor/jfsh) | Jellyfin TUI |
| [managarr](https://github.com/j-morano/managarr) | Arr media manager TUI |
| [zathura](https://pwmt.org/projects/zathura/) | PDF viewer |

Install all AUR packages:
```bash
yay -S hyprland uwsm waybar dunst mako hypridle hyprlock hyprsunset omarchy fcitx5 fcitx5-rime kitty yazi superfile zellij mpv rmpc swayosd walker glow jfsh managarr zathura
```