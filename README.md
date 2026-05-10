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

1. **Links configs** — Scans `configs/` and symlinks unlinked dirs into `~/.config/`
2. **Links themes** — Scans `themes/omarchy/` and symlinks themes into `~/.config/omarchy/themes/`

### Manual configuration

Some config values are personal and require manual editing:

#### Config files

These files contain settings you may want to adjust manually:

| File | What to change |
|------|----------------|
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

- **`.zshrc`** — Main Zsh config. Auto-installs required tools on first run (oh-my-posh, aliae, zoxide, lsd, zinit, fzf, etc.)
- **Aliae** — Alias manager. Configs live in `.aliae/` and are aggregated via `~/.dotfiles/configs/.aliae.yml`. The `ALIAE_CONFIG` env var points to this.
- **zinit** — Plugin manager, bootstrapped in `.zshrc`

---

## Scripts

Scripts in `scripts/` are added to PATH via `configs/hypr/envs.conf`. Each is standalone and can be called from anywhere.

| Script | What it does |
|--------|-------------|
| `hypr-reload` | Runs `hyprctl reload` and sends a desktop notification with the result |
| `dnd-toggle` | Toggles dunst do-not-disturb mode on/off |
| `caffeine-toggle` | Toggles hypridle (prevents screen sleep) on/off |
| `waybar-toggle` | Hides/shows waybar and adjusts window gaps accordingly |
| `playlist-gen` | Generates mpv playlist from directory |

### Script details

**`playlist-gen`** - Generates an m3u8 playlist from a directory of audio files.
```bash
playlist-gen /path/to/music  # outputs playlist.m3u8 in current directory
```

**Waybar music indicator** (`configs/waybar/indicators/music.sh`) - Shows current playing track from MPD via rmpc. Click to launch rmpc, right-click to toggle play/pause.

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

## Prerequisites

These tools are required for the desktop environment to work. Most are auto-installed by `.zshrc` on first run, but install manually if needed.

| Tool | Purpose |
|------|---------|
| [Hyprland](https://hyprland.org/) | Wayland compositor / window manager |
| [uwsm](https://github.com/Vladimir-csp/uwsm) | Wayland session manager |
| [waybar](https://github.com/Alexays/Waybar) | Status bar |
| [dunst](https://github.com/dunst-project/dunst) | Notification daemon |
| [hypridle](https://github.com/hyprland/hypridle) | Idle management |
| [hyprlock](https://github.com/hyprland/hyprlock) | Screen locker |
| [omarchy](https://github.com/jL城外/omarchy) | Desktop environment framework |
| [fcitx5](https://fcitx-im.org/) | Input method |
| [Alacritty](https://alacritty.org/) / [Kitty](https://sw.kovidgoyal.net/kitty/) / [Ghostty](https://ghostty.org/) | Terminal emulator |
| [yazi](https://github.com/sxyazi/yazi) / [superfile](https://github.com/MHNightCat/superfile) | Terminal file managers |
| [zellij](https://zellij.dev/) | Terminal multiplexer |
| [mpv](https://mpv.io/) | Video player |
| [jfsh](https://github.com/ApexAllMonitor/jfsh) | Jellyfin TUI |
| [managarr](https://github.com/j-morano/managarr) | Arr media manager TUI |

Install all required AUR packages:
```bash
yay -S hyprland uwsm waybar hypridle hyprlock omarchy fcitx5 fcitx5-rime alacritty kitty ghostty yazi superfile zellij mpv jfsh managarr
```