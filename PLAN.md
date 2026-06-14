# Cross-Platform Migration Plan

## Goal

Make these dotfiles work on both Arch Linux (Hyprland/omarchy) and macOS (Ventura+).
Shared configs (zsh, aliae, git, etc.) should be platform-agnostic; platform-specific
configs (Hyprland, omarchy, Ghostty, etc.) are guarded by OS conditions or skipped
at install time.

## Architecture

```
~/.zshrc  (machine-specific, sources dotfiles)
  └─ ~/.dotfiles/.zshrc  (shared, cross-platform)
       ├─ configs/.zsh/plugins.zsh   ← pure plugin loading (zinit pre-sourced by machine)
       ├─ configs/.zsh/inits.zsh     ← tool init (oh-my-posh, aliae, zoxide, fzf)
       └─ configs/.zsh/functions.zsh ← custom functions
```

- Machine `.zshrc` sources zinit (platform-specific path), then sources `~/.dotfiles/.zshrc`
- `plugins.zsh` assumes zinit is already loaded (`$+functions[zinit]`)
- Platform-specific aliases use aliae's `.OS` conditions
- Install script detects OS and skips irrelevant configs

---

## Phase 1 — Cross-platform Shell & CLI

### 1a. `.zshrc` — Guard `SWAYSOCK` aliases

**File:** `.zshrc:37-38`
**Change:** Wrap `yazi`/`spf` aliases with `[[ $OSTYPE == linux-* ]]` guard.
**Why:** These must be defined before `files-widget` function (L41) since zsh expands
aliases at function-definition time. aliae loads too late (L72). The guard keeps them
as no-ops on macOS.

Before:
```zsh
alias yazi='SWAYSOCK= yazi'
alias spf='SWAYSOCK= spf'
```

After:
```zsh
[[ $OSTYPE == linux-* ]] && alias yazi='SWAYSOCK= yazi' && alias spf='SWAYSOCK= spf'
```

---

### 1b. `plugins.zsh` — Remove zinit path sourcing

**File:** `configs/.zsh/plugins.zsh`
**Change:** Remove the `[[ -f /usr/share/zinit/zinit.zsh ]]` sourcing block. Keep only the
`(( $+functions[zinit] ))` guard.
**Why:** Each machine's `.zshrc` sources zinit at its own platform-specific path before
dotfiles load. Arch: `/usr/share/zinit/zinit.zsh` (from `yay -S zinit`). macOS:
`/opt/homebrew/opt/zinit/zinit.zsh` (from `brew install zinit`). The shared dotfiles
shouldn't hardcode any platform path.

Before:
```zsh
# Source zinit if available
if [[ -f /usr/share/zinit/zinit.zsh ]]; then
  source /usr/share/zinit/zinit.zsh
fi
```

After:
```zsh
# (removed — zinit is sourced by each machine's ~/.zshrc before dotfiles load)
```

---

### 1c. `core.yml` — Guard Linux-only aliases

**File:** `configs/.aliae/alias/core.yml`
**Changes:**

| Alias | Linux | macOS | Condition |
|-------|-------|-------|-----------|
| `dsks` | `lsblk --output ... --tree --ascii` | `diskutil list` | Both, `eq .OS` |
| `rm` | `rm --preserve-root` | `rm -i` | `eq .OS "linux"` / `"darwin"` |
| `i`–`yown` | all `yay` aliases | n/a | `eq .OS "linux"` |

**Why:** `lsblk` is Linux-only (macOS uses `diskutil`). BSD `rm` lacks `--preserve-root`.
`yay` is Arch-only.

---

### 1d. `omarchy.yml` — Guard all aliases

**File:** `configs/.aliae/alias/omarchy.yml`
**Change:** Add `if: eq .OS "linux"` to every alias.
**Why:** All depend on `omarchy-*` commands and `hyprctl` — not available on macOS.

---

### 1e. `path.yml` — Add macOS (darwin) block

**File:** `configs/.aliae/path.yml`
**Change:** Add a `darwin` block mirroring the `linux` paths, plus Homebrew-specific
paths (`/opt/homebrew/bin`, `$(brew --prefix)/go/bin`, etc.)

Before:
```yaml
- value: |
    {{ .Home }}/.dotfiles/scripts/
    {{ .Home }}/bin/
    {{ .Home }}/go/bin/
    {{ .Home }}/.cargo/bin/
  if: eq .OS "linux"
```

After:
```yaml
- value: |
    {{ .Home }}/.dotfiles/scripts/
    {{ .Home }}/bin/
    {{ .Home }}/go/bin/
    {{ .Home }}/.cargo/bin/
  if: eq .OS "linux"

- value: |
    {{ .Home }}/.dotfiles/scripts/
    /opt/homebrew/bin/
    /opt/homebrew/sbin/
    {{ .Home }}/go/bin/
    {{ .Home }}/.cargo/bin/
  if: eq .OS "darwin"
```

---

### 1f. New: `brew.yml` — Sparse Homebrew aliases

**File:** `configs/.aliae/alias/brew.yml`
**Content:** Spare set of ~7 brew aliases, all guarded with `if: eq .OS "darwin"`.

| Alias | Value |
|-------|-------|
| `bup` | `brew update && brew upgrade && brew cleanup` |
| `bi` | `brew install` |
| `brm` | `brew uninstall` |
| `bse` | `brew search` |
| `bin` | `brew info` |
| `bls` | `brew list` |
| `bc` | `brew doctor` |

**Why:** Mirrors the convenience of `yay` aliases for macOS package management.

**aliae.yml include:** Add `!include "./alias/brew.yml"` to the alias list.

---

## Phase 2 — Platform Config Tweaks

### 2a. New: `ghostty/config.ghostty`

**Path:** `configs/ghostty/config.ghostty`
**Content:** User's current Ghostty config from `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`,
with the duplicate `window-height` key removed (L22: `30` was overridden by L31: `200`).
**Install:** Symlinked to `~/Library/Application Support/com.mitchellh.ghostty/config` on macOS.
**Why:** Ghostty is the macOS terminal emulator (analogous to kitty on Linux).

### 2b. `mpv/mpv.conf` — Guard `screen-name`

**File:** `configs/mpv/mpv.conf:25`
**Change:** Comment out `screen-name=DP-1` on macOS, or wrap in a profile condition.
**Why:** `DP-1` is a Linux display port name. macOS display names differ (e.g. `NSGlobal`).

### 2c. `superfile/config.toml` — Guard PDF viewer

**File:** `configs/superfile/config.toml:175`
**Change:** `pdf = "zathura"` → conditional or per-platform.
**Why:** `zathura` is Linux-only. macOS can use `/System/Applications/Preview.app` or
`sioyek`/`skim`.

---

## Phase 3 — Install Script

### 3a. OS detection and platform-aware config linking

- Detect OS at top of `install.sh`
- Skip Linux-only config dirs on macOS: `hypr/`, `waybar/`, `dunst/`, `swayosd/`,
  `walker/`, `omarchy/`, `vicinae/`, `gtk-3.0/`, `gtk-4.0/`, `.mako/`
- Skip macOS-only config dirs on Linux: `ghostty/`
- Use `brew` for dependency installation on macOS, `yay` on Arch

### 3b. Platform-aware script selection

- Linux-only scripts: `hypr-reload`, `caffeine-toggle`, `dnd-toggle`, `waybar-toggle`,
  `virtmon-toggle`, `workspace-osd`, `omarchy-launch-vicinae`, `omarchy-restart-vicinae`
- macOS scripts: (TBD — SketchyBar toggles, etc., deferred)
- Cross-platform: `playlist-gen`
- `path.yml` should only add `~/.dotfiles/scripts/` dirs for scripts that exist on
  the current platform

### 3c. Platform-aware dependency list

- Linux deps (via `yay`): oh-my-posh, aliae, zoxide, lsd, zinit, fzf, glow, yt-dlp,
  jfsh, yazi, superfile, dunst, zathura
- macOS deps (via `brew`): oh-my-posh, aliae, zoxide, lsd, fzf, glow, yt-dlp,
  yazi, superfile
- (Note: dunst, zathura, jfsh are Linux-only; ghostty config is symlinked separately)

---

## Follow-ups

- [ ] `brew install aliae` on macOS
- [ ] Fix duplicate `!include "./alias/core.yml"` in `aliae.yml:4` (lines 2 and 4)
- [ ] `install.sh`: add brew alias `--f` (force) flag handling or skip already-installed
- [ ] Add `configs/.mako/` Linux-only dir to install skip list if created later

Phases 1-3 complete. `install.sh` detects OS and adapts every section.

---

## Branch Strategy

Use a **single branch** with OS checks inline (`[[ "$PLATFORM" == "linux" ]]`, etc.).
Platform-specific files live in the same repo (e.g. `configs/ghostty/`, `configs/hypr/`)
and are selected at install time via `install.sh` skip lists.

Four branches (lin/mac/win + cross-platform) was considered and rejected — too much
maintenance overhead for every change.

---
