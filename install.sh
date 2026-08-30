#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$DOTFILES_DIR/configs"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
PRE_INSTALL_BACKUP_DIR="$XDG_CONFIG_HOME/.pre-install-backup"

# === FLAG PARSING ===
LINK_ONLY=0
DRY_RUN=0
for arg in "$@"; do
  [[ "$arg" == "--link-only" ]] && LINK_ONLY=1
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=1
done

# === CLEANUP TRAP ===
# If the script is interrupted mid-linking, report the state so the user knows
# what was linked before failure.
_LINKED_DURING_RUN=()
cleanup() {
  local code=$?
  if [[ $code -ne 0 && ${#_LINKED_DURING_RUN[@]} -gt 0 ]]; then
    echo
    msg --bold --foreground 3 "Interrupted! These configs were already linked:"
    for app in "${_LINKED_DURING_RUN[@]}"; do
      msg --foreground 3 "  $app"
    done
    msg --foreground 3 "Run with --dry-run to preview, or use restore.sh to undo."
  fi
}
trap cleanup EXIT

# === UI HELPERS ===
# In link-only mode, use plain echo. In interactive mode, use gum.
HAS_GUM=0
if [[ $LINK_ONLY -eq 0 ]]; then
  command -v gum &>/dev/null && HAS_GUM=1
fi

msg() {
  if [[ $HAS_GUM -eq 1 ]]; then
    gum style "$@"
  else
    # Strip gum flags, print only positional text
    local args=()
    local skip_next=0
    for arg in "$@"; do
      if [[ $skip_next -eq 1 ]]; then
        skip_next=0
        continue
      fi
      case "$arg" in
        --foreground|--padding|--show-help|--affirmative|--negative|--default)
          skip_next=1
          ;;
        --*)
          # Standalone flags like --bold: skip
          ;;
        *)
          args+=("$arg")
          ;;
      esac
    done
    printf '%s\n' "${args[*]}"
  fi
}

msg_color() {
  local color="$1"; shift
  if [[ $HAS_GUM -eq 1 ]]; then
    gum style --foreground "$color" "$@"
  else
    # Same flag-stripping as msg
    local args=()
    local skip_next=0
    for arg in "$@"; do
      if [[ $skip_next -eq 1 ]]; then
        skip_next=0
        continue
      fi
      case "$arg" in
        --foreground|--padding|--show-help|--affirmative|--negative|--default)
          skip_next=1
          ;;
        --*)
          ;;
        *)
          args+=("$arg")
          ;;
      esac
    done
    printf '%s\n' "${args[*]}"
  fi
}

confirm() {
  if [[ $HAS_GUM -eq 1 ]]; then
    gum confirm "$@"
  else
    read -r -p "${*: -1} [Y/n] " reply
    [[ "${reply,,}" != "n" ]]
  fi
}

# Ensure gum is available in interactive mode
if [[ $LINK_ONLY -eq 0 ]] && [[ $HAS_GUM -eq 0 ]]; then
  msg_color 3 "Installing gum..."
  if command -v yay &>/dev/null; then
    yay -S gum --noconfirm || { msg_color 1 "Error: gum is required but not installed. Install it first."; exit 1; }
    HAS_GUM=1
  else
    msg_color 1 "Error: gum is required but not installed. Install it first."
    exit 1
  fi
fi

# === CHECK SYMLINK ===
check_symlink() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" ]]; then
    local link_target
    link_target=$(readlink "$target")
    if [[ "$link_target" == "$source" ]]; then
      return 0
    fi
    return 2
  elif [[ -e "$target" ]]; then
    return 3
  else
    return 1
  fi
}

# === DRY-RUN HELPER ===
dry_run_guard() {
  if [[ $DRY_RUN -eq 1 ]]; then
    msg_color 8 "(dry-run) $1"
    return 1
  fi
  return 0
}

# === PRE-FLIGHT CHECKS ===
preflight_warnings=()
if ! command -v omarchy &>/dev/null; then
  preflight_warnings+=("omarchy not found (command 'omarchy' missing) — omarchy-* commands and themed templates won't work")
fi
if command -v omarchy &>/dev/null && [[ ! -d "$XDG_CONFIG_HOME/omarchy/current/theme" ]]; then
  preflight_warnings+=("omarchy is installed but no theme is set — run 'omarchy theme-set <name>' after install")
fi
if ! command -v yay &>/dev/null && ! command -v pacman &>/dev/null; then
  preflight_warnings+=("neither yay nor pacman found — dependency installs will be skipped")
fi

# Terminal sizing (from omarchy)
TERM_WIDTH=80
TERM_HEIGHT=24

if [[ -e /dev/tty ]]; then
  TERM_SIZE=$(stty size 2>/dev/null </dev/tty || true) && {
    TERM_HEIGHT=$(echo "$TERM_SIZE" | cut -d' ' -f1)
    TERM_WIDTH=$(echo "$TERM_SIZE" | cut -d' ' -f2)
  }
fi

LOGO_PATH="$DOTFILES_DIR/logo.txt"
LOGO_WIDTH=$(awk '{ if (length > max) max = length } END { print max+0 }' "$LOGO_PATH" 2>/dev/null || echo 0)
LOGO_HEIGHT=$(wc -l <"$LOGO_PATH" 2>/dev/null || echo 0)
PADDING_LEFT=$(((TERM_WIDTH - LOGO_WIDTH) / 2))
PADDING_LEFT_SPACES=$(printf "%*s" $PADDING_LEFT "")

clear_logo() {
  printf "\033[H\033[2J"
  if [[ $HAS_GUM -eq 1 ]]; then
    gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "$(<"$LOGO_PATH")"
  else
    cat "$LOGO_PATH"
  fi
}

# Intro
clear_logo
if [[ $DRY_RUN -eq 1 ]]; then
  msg --bold --foreground 3 "DRY-RUN MODE — no changes will be made"
  echo
fi
msg --padding "1 0 0 $PADDING_LEFT" "Welcome to dotfiles bootstrap!"
msg_color 8 --padding "1 0 0 $PADDING_LEFT" "This will link your config directories."
echo

# Show preflight warnings
if [[ ${#preflight_warnings[@]} -gt 0 ]]; then
  msg --bold --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Pre-flight warnings:"
  for w in "${preflight_warnings[@]}"; do
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  ! $w"
  done
  echo
fi

# === PRE-INSTALL BACKUP SNAPSHOT ===
# Snapshot the state of all files that will be modified, before any linking.
# This gives a full rollback point regardless of what happens next.
pre_install_snapshot() {
  [[ $DRY_RUN -eq 1 ]] && return 0

  local manifest="$PRE_INSTALL_BACKUP_DIR/manifest.txt"
  mkdir -p "$PRE_INSTALL_BACKUP_DIR"

  # Snapshot conflict configs (real files that will be replaced)
  for app in "${conflicting[@]}" "${existing_links[@]}"; do
    local target="$XDG_CONFIG_HOME/$app"
    if [[ -L "$target" ]]; then
      local link_target
      link_target=$(readlink "$target")
      echo "symlink $app -> $link_target" >> "$manifest"
    elif [[ -e "$target" ]]; then
      local ts
      ts=$(date +%Y%m%d-%H%M%S)
      cp -a "$target" "$PRE_INSTALL_BACKUP_DIR/$app.$ts"
      echo "file $app $PRE_INSTALL_BACKUP_DIR/$app.$ts" >> "$manifest"
    fi
  done

  msg_color 8 "  Pre-install snapshot saved to $PRE_INSTALL_BACKUP_DIR"
}

# === BACKUP ROTATION ===
# Keep only the most recent backups to prevent unbounded growth.
rotate_backups() {
  local backup_dir="${1:-$XDG_CONFIG_HOME/.backup}"
  local keep="${2:-20}"

  [[ ! -d "$backup_dir" ]] && return 0

  local count
  count=$(find "$backup_dir" -maxdepth 1 -type f | wc -l)
  if [[ $count -gt $keep ]]; then
    local to_remove=$((count - keep))
    find "$backup_dir" -maxdepth 1 -type f -printf '%T+ %p\n' 2>/dev/null \
      | sort \
      | head -n "$to_remove" \
      | cut -d' ' -f2- \
      | xargs -r rm -f
    msg_color 8 "  Rotated backups (removed $to_remove old, kept $keep)"
  fi
}

# === AUTO-SOURCE .ZSHRC ===
# Ensures the user's ~/.zshrc picks up dotfiles/.zshrc, so a fresh install works
# without manual symlinking.
if [[ $LINK_ONLY -eq 1 ]]; then
  msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped zshrc setup (link-only mode)"
else
  ZSHRC_TARGET="$HOME/.zshrc"
  ZSHRC_SOURCE_LINE="source $DOTFILES_DIR/.zshrc"

  if [[ ! -f "$DOTFILES_DIR/.zshrc" ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "Skipped zshrc: $DOTFILES_DIR/.zshrc not found"
  else
    zshrc_already_sources=false
    if [[ -f "$ZSHRC_TARGET" ]] && grep -qF "$ZSHRC_SOURCE_LINE" "$ZSHRC_TARGET" 2>/dev/null; then
      zshrc_already_sources=true
    fi

    if $zshrc_already_sources; then
      msg_color 2 --padding "0 0 0 $PADDING_LEFT" "~/.zshrc already sources dotfiles"
    else
      if confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --affirmative "Add source line" --negative "Skip" "Add 'source $ZSHRC_SOURCE_LINE' to ~/.zshrc?"; then
        mkdir -p "$(dirname "$ZSHRC_TARGET")"
        if [[ -f "$ZSHRC_TARGET" ]]; then
          # Append, with a leading newline if the file doesn't end with one
          if [[ -s "$ZSHRC_TARGET" ]] && [[ "$(tail -c1 "$ZSHRC_TARGET")" != $'\n' ]]; then
            printf '\n%s\n' "$ZSHRC_SOURCE_LINE" >> "$ZSHRC_TARGET"
          else
            printf '%s\n' "$ZSHRC_SOURCE_LINE" >> "$ZSHRC_TARGET"
          fi
        else
          printf '%s\n' "$ZSHRC_SOURCE_LINE" > "$ZSHRC_TARGET"
        fi
        msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Added source line to ~/.zshrc"
      else
        msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped zshrc. Run manually: ln -s $DOTFILES_DIR/.zshrc ~/.zshrc"
      fi
    fi
    echo
  fi
fi

# === SECRETS FILE ===
# The repo's per-user secret files (configs/.zsh/functions.zsh,
# configs/managarr/config.yml) reference env vars defined in a separate
# runtime file. This file is gitignored, chmod 600, and sourced from the
# sanitized functions.zsh.
if [[ $LINK_ONLY -eq 1 ]]; then
  msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped secrets file setup (link-only mode)"
else
  SECRETS_DIR="$HOME/.local/share/dotfiles-secrets"
  SECRETS_FILE="$SECRETS_DIR/env.sh"

  if [[ -f "$SECRETS_FILE" ]]; then
    perms=$(stat -c '%a' "$SECRETS_FILE" 2>/dev/null || stat -f '%A' "$SECRETS_FILE" 2>/dev/null || echo "unknown")
    if [[ "$perms" != "600" ]]; then
      msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  ! $SECRETS_FILE exists but is mode $perms (expected 600), tightening"
      chmod 600 "$SECRETS_FILE"
    else
      msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Secrets file present: $SECRETS_FILE (mode 600)"
    fi
  else
    if confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --affirmative "Create" --negative "Skip" "Create secrets file at $SECRETS_FILE?"; then
      mkdir -p "$SECRETS_DIR"
      cat > "$SECRETS_FILE" <<'SECRETS_TEMPLATE'
# dotfiles per-user secrets — chmod 600, gitignored.
# Fill in the values for the services you use; leave empty to skip.
# qBittorrent on zimaos (used by `qti` in configs/.zsh/functions.zsh)
export QBIT_ZIMA_PASS=""
# qBittorrent on localhost  (used by `qui` in configs/.zsh/functions.zsh)
export QBIT_LOCAL_PASS=""
# Radarr API key (Settings > General > API Key)
export RADARR_API_TOKEN=""
# Sonarr API key (Settings > General > API Key)
export SONARR_API_TOKEN=""
SECRETS_TEMPLATE
      chmod 600 "$SECRETS_FILE"
      msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Created $SECRETS_FILE (mode 600) — populate before using qti/qui/managarr"
    else
      msg_color 8 --padding "0 0 0 $PADDING_LEFT" "  Skipped secrets file. functions.zsh and managarr will fail until you create $SECRETS_FILE"
    fi
  fi
fi
echo

# Find configs that need symlinking
missing_links=()
broken_links=()
existing_links=()
conflicting=()

# Config dirs that must NOT be symlinked via the generic loop:
#  - omarchy: handled by the special themes/hooks/themed linking below
#  - git: omarchy manages ~/.config/git/config; our copy would clobber it
skip_dirs=("omarchy" "git")

# Apps whose configs are owned by omarchy (regenerated on theme-set). If a copy
# of one of these ever appears in configs/, skip it and warn instead of
# overwriting the omarchy-managed file in ~/.config.
#   kitty, hypr, foot, ghostty, alacritty — terminal emulators
#   git — omarchy manages ~/.config/git/config
#   tmux, lazygit, btop — terminal UIs
#   obsidian, imv, herdr — productivity/media apps
#   wireplumber — audio pipewire session manager
#   xournalpp — note-taking app
#   chromium, fcitx5 — browser and input method
omarchy_managed=("kitty" "hypr" "git" "foot" "ghostty" "alacritty" "tmux" "lazygit" "btop" "obsidian" "imv" "herdr" "wireplumber" "xournalpp" "chromium" "fcitx5")
is_skip() {
  for skip in "${skip_dirs[@]}"; do
    [[ "$1" == "$skip" ]] && return 0
  done
  return 1
}
is_omarchy_managed() {
  for app in "${omarchy_managed[@]}"; do
    [[ "$1" == "$app" ]] && return 0
  done
  return 1
}

for app_dir in "$CONFIG_DIR"/*; do
  [[ -d "$app_dir" ]] || continue
  app_name=$(basename "$app_dir")
  target="$XDG_CONFIG_HOME/$app_name"

  is_skip "$app_name" && continue
  if is_omarchy_managed "$app_name"; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  Skipped $app_name (omarchy-managed; would conflict with built-in config)"
    continue
  fi

  if check_symlink "$app_dir" "$target"; then
    result=0
  else
    result=$?
  fi

  case $result in
    0) existing_links+=("$app_name") ;;
    1) missing_links+=("$app_name") ;;
    2) broken_links+=("$app_name") ;;
    3) conflicting+=("$app_name") ;;
  esac
done

# Show symlink status
if [[ ${#existing_links[@]} -gt 0 ]]; then
  msg_color 2 --padding "1 0 0 $PADDING_LEFT" "Already linked (${#existing_links[@]}):"
  for app in "${existing_links[@]}"; do
    msg --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

if [[ ${#broken_links[@]} -gt 0 ]]; then
  msg_color 3 --padding "1 0 0 $PADDING_LEFT" "Broken links (${#broken_links[@]}):"
  for app in "${broken_links[@]}"; do
    msg --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

if [[ ${#conflicting[@]} -gt 0 ]]; then
  msg_color 1 --padding "1 0 0 $PADDING_LEFT" "Conflicts (already exist, not symlinked) (${#conflicting[@]}):"
  for app in "${conflicting[@]}"; do
    msg --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

if [[ ${#missing_links[@]} -gt 0 ]]; then
  msg_color 8 --padding "1 0 0 $PADDING_LEFT" "Need linking (${#missing_links[@]}):"
  for app in "${missing_links[@]}"; do
    msg --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

echo

# Take pre-install snapshot before any modifications
if [[ ${#missing_links[@]} -gt 0 || ${#broken_links[@]} -gt 0 || ${#conflicting[@]} -gt 0 ]]; then
  pre_install_snapshot
fi

# === OMAVAULT BACKUP (safety net) ===
# If omavault is present, snapshot the current machine configs into
# ~/omarchy-vault before any config is replaced by a symlink. This captures the
# originals (e.g. gtk-3.0/gtk-4.0) before we link over them. Non-destructive,
# no root; only runs when vault.py exists.
OMA_VAULT_PY="$XDG_CONFIG_HOME/omarchy/plugins/io.github.mutahir.omavault/vault.py"
if [[ -f "$OMA_VAULT_PY" ]]; then
  msg_color 3 --padding "1 0 0 $PADDING_LEFT" "Omavault snapshot (pre-link safety net)..."
  python3 "$OMA_VAULT_PY" snapshot || true
  echo
else
  msg_color 8 --padding "1 0 0 $PADDING_LEFT" "Omavault not found — skipping pre-link snapshot."
  echo
fi

# Ask about symlinking
if [[ ${#missing_links[@]} -gt 0 ]] || [[ ${#broken_links[@]} -gt 0 ]]; then
  if [[ $LINK_ONLY -eq 1 ]] || [[ $DRY_RUN -eq 1 ]] || confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link configs" --negative "Skip"; then
    symlink_count=0

    for app in "${missing_links[@]}" "${broken_links[@]}"; do
      source_path="$CONFIG_DIR/$app"
      target_path="$XDG_CONFIG_HOME/$app"

      if dry_run_guard "Would link $app"; then
        if [[ -L "$target_path" ]]; then
          rm "$target_path"
        fi

        ln -s "$source_path" "$target_path"
        _LINKED_DURING_RUN+=("$app")
        msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $app"
        symlink_count=$((symlink_count + 1))
      fi
    done

    msg --padding "1 0 0 $PADDING_LEFT" "Linked $symlink_count config(s)."
  else
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped symlinking."
  fi
fi

# === CONFLICT HANDLING ===
if [[ ${#conflicting[@]} -gt 0 ]]; then
  BACKUP_DIR="$XDG_CONFIG_HOME/.backup"
  echo
  msg --bold --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Conflicting configs (${#conflicting[@]}):"
  for i in "${!conflicting[@]}"; do
    msg --padding "0 0 0 $PADDING_LEFT" "  $((i+1))) ${conflicting[$i]}"
  done
  msg --padding "0 0 0 $PADDING_LEFT" ""

  if [[ $LINK_ONLY -eq 1 ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  (link-only: backing up all conflicts automatically)"
    selected=("${conflicting[@]}")
  else
    if [[ $HAS_GUM -eq 1 ]]; then
      choice=$(gum input --prompt "> " --placeholder "Numbers (e.g. 1,3), 'a' for all, 'n' to skip")
    else
      read -r -p "> " choice
    fi

    selected=()
    case "${choice,,}" in
      a|all)
        selected=("${conflicting[@]}")
        ;;
      n|none|"")
        msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped all conflicts."
        ;;
      *)
        IFS=',' read -ra parts <<< "$choice"
        for part in "${parts[@]}"; do
          part="${part// /}"
          idx=$((part - 1))
          [[ $idx -ge 0 && $idx -lt ${#conflicting[@]} ]] && selected+=("${conflicting[$idx]}")
        done
        ;;
    esac
  fi

  if [[ ${#selected[@]} -gt 0 ]]; then
    mkdir -p "$BACKUP_DIR"
    for app in "${selected[@]}"; do
      source_path="$CONFIG_DIR/$app"
      target_path="$XDG_CONFIG_HOME/$app"
      timestamp=$(date +%Y%m%d-%H%M%S)

      if dry_run_guard "Would back up $app and link"; then
        mv "$target_path" "$BACKUP_DIR/$app.$timestamp"
        ln -s "$source_path" "$target_path"
        _LINKED_DURING_RUN+=("$app")
        msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Backed up $app → .backup/$app.$timestamp & linked"
      fi
    done
    msg_color 2 --padding "1 0 0 $PADDING_LEFT" "Linked ${#selected[@]} conflict(s)."

    # Rotate backups after adding new ones
    rotate_backups "$BACKUP_DIR"
  fi
fi

echo

# === THEMES (omarchy) ===
# The omarchy/openCode theme, hook, and themed-template linking below only runs
# in interactive (non-link-only) mode — link-only applies plain config symlinks.
if [[ $LINK_ONLY -eq 0 ]]; then
OMARCHY_THEMES_SOURCE="$DOTFILES_DIR/themes/omarchy"
OMARCHY_THEMES_TARGET="$XDG_CONFIG_HOME/omarchy/themes"

if [[ -d "$OMARCHY_THEMES_SOURCE" ]]; then
  msg --bold --padding "1 0 0 $PADDING_LEFT" "Themes (omarchy):"

  theme_existing=()
  theme_missing=()
  theme_broken=()
  theme_conflicts=()

  for theme_dir in "$OMARCHY_THEMES_SOURCE"/*; do
    [[ -d "$theme_dir" ]] || continue
    theme_name=$(basename "$theme_dir")
    target="$OMARCHY_THEMES_TARGET/$theme_name"

    if check_symlink "$theme_dir" "$target"; then
      result=0
    else
      result=$?
    fi

    case $result in
      0) theme_existing+=("$theme_name") ;;
      1) theme_missing+=("$theme_name") ;;
      2) theme_broken+=("$theme_name") ;;
      3) theme_conflicts+=("$theme_name") ;;
    esac
  done

  if [[ ${#theme_existing[@]} -gt 0 ]]; then
    msg_color 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#theme_existing[@]}):"
    for theme in "${theme_existing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#theme_conflicts[@]} -gt 0 ]]; then
    msg_color 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#theme_conflicts[@]}):"
    for theme in "${theme_conflicts[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#theme_missing[@]} -gt 0 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#theme_missing[@]}):"
    for theme in "${theme_missing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#theme_broken[@]} -gt 0 ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#theme_broken[@]}):"
    for theme in "${theme_broken[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  echo

  if [[ ${#theme_missing[@]} -gt 0 ]] || [[ ${#theme_broken[@]} -gt 0 ]]; then
    if confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link themes" --negative "Skip"; then
      theme_count=0

      for theme in "${theme_missing[@]}" "${theme_broken[@]}"; do
        source_path="$OMARCHY_THEMES_SOURCE/$theme"
        target_path="$OMARCHY_THEMES_TARGET/$theme"

        if dry_run_guard "Would link theme $theme"; then
          if [[ -L "$target_path" ]]; then
            rm "$target_path"
          fi

          ln -s "$source_path" "$target_path"
          _LINKED_DURING_RUN+=("$theme")
          msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $theme"
          theme_count=$((theme_count + 1))
        fi
      done

      msg --padding "0 0 0 $PADDING_LEFT" "Linked $theme_count theme(s)."
    else
      msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped theme linking."
    fi
  fi

  echo
fi

# === OMARCHY HOOKS ===
OMARCHY_HOOKS_SOURCE="$DOTFILES_DIR/configs/omarchy/hooks"
OMARCHY_HOOKS_TARGET="$XDG_CONFIG_HOME/omarchy/hooks"

if [[ -d "$OMARCHY_HOOKS_SOURCE" ]]; then
  msg --bold --padding "1 0 0 $PADDING_LEFT" "Omarchy hooks:"

  hook_existing=()
  hook_missing=()
  hook_broken=()
  hook_conflicts=()

  for hook_file in "$OMARCHY_HOOKS_SOURCE"/*; do
    [[ -f "$hook_file" ]] || continue
    hook_name=$(basename "$hook_file")
    target="$OMARCHY_HOOKS_TARGET/$hook_name"

    if check_symlink "$hook_file" "$target"; then
      result=0
    else
      result=$?
    fi

    case $result in
      0) hook_existing+=("$hook_name") ;;
      1) hook_missing+=("$hook_name") ;;
      2) hook_broken+=("$hook_name") ;;
      3) hook_conflicts+=("$hook_name") ;;
    esac
  done

  if [[ ${#hook_existing[@]} -gt 0 ]]; then
    msg_color 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#hook_existing[@]}):"
    for hook in "${hook_existing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  if [[ ${#hook_conflicts[@]} -gt 0 ]]; then
    msg_color 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#hook_conflicts[@]}):"
    for hook in "${hook_conflicts[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  if [[ ${#hook_missing[@]} -gt 0 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#hook_missing[@]}):"
    for hook in "${hook_missing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  if [[ ${#hook_broken[@]} -gt 0 ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#hook_broken[@]}):"
    for hook in "${hook_broken[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  echo

  if [[ ${#hook_missing[@]} -gt 0 ]] || [[ ${#hook_broken[@]} -gt 0 ]]; then
    if confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link hooks" --negative "Skip"; then
      hook_count=0

      for hook in "${hook_missing[@]}" "${hook_broken[@]}"; do
        source_path="$OMARCHY_HOOKS_SOURCE/$hook"
        target_path="$OMARCHY_HOOKS_TARGET/$hook"

        if dry_run_guard "Would link hook $hook"; then
          if [[ -L "$target_path" ]]; then
            rm "$target_path"
          fi

          ln -s "$source_path" "$target_path"
          _LINKED_DURING_RUN+=("$hook")
          msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $hook"
          hook_count=$((hook_count + 1))
        fi
      done

      msg --padding "0 0 0 $PADDING_LEFT" "Linked $hook_count hook(s)."
    else
      msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped hook linking."
    fi
  fi

  echo
fi

# === OMARCHY THEMED TEMPLATES ===
OMARCHY_THEMED_SOURCE="$DOTFILES_DIR/configs/omarchy/themed"
OMARCHY_THEMED_TARGET="$XDG_CONFIG_HOME/omarchy/themed"

if [[ -d "$OMARCHY_THEMED_SOURCE" ]]; then
  msg --bold --padding "1 0 0 $PADDING_LEFT" "Omarchy themed templates:"

  themed_existing=()
  themed_missing=()
  themed_broken=()
  themed_conflicts=()

  for tpl_file in "$OMARCHY_THEMED_SOURCE"/*; do
    [[ -f "$tpl_file" ]] || continue
    tpl_name=$(basename "$tpl_file")
    target="$OMARCHY_THEMED_TARGET/$tpl_name"

    if check_symlink "$tpl_file" "$target"; then
      result=0
    else
      result=$?
    fi

    case $result in
      0) themed_existing+=("$tpl_name") ;;
      1) themed_missing+=("$tpl_name") ;;
      2) themed_broken+=("$tpl_name") ;;
      3) themed_conflicts+=("$tpl_name") ;;
    esac
  done

  if [[ ${#themed_existing[@]} -gt 0 ]]; then
    msg_color 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#themed_existing[@]}):"
    for tpl in "${themed_existing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  if [[ ${#themed_conflicts[@]} -gt 0 ]]; then
    msg_color 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#themed_conflicts[@]}):"
    for tpl in "${themed_conflicts[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  if [[ ${#themed_missing[@]} -gt 0 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#themed_missing[@]}):"
    for tpl in "${themed_missing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  if [[ ${#themed_broken[@]} -gt 0 ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#themed_broken[@]}):"
    for tpl in "${themed_broken[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  echo

  if [[ ${#themed_missing[@]} -gt 0 ]] || [[ ${#themed_broken[@]} -gt 0 ]]; then
    if confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link themed templates" --negative "Skip"; then
      themed_count=0

      for tpl in "${themed_missing[@]}" "${themed_broken[@]}"; do
        source_path="$OMARCHY_THEMED_SOURCE/$tpl"
        target_path="$OMARCHY_THEMED_TARGET/$tpl"

        if dry_run_guard "Would link themed template $tpl"; then
          if [[ -L "$target_path" ]]; then
            rm "$target_path"
          fi

          ln -s "$source_path" "$target_path"
          _LINKED_DURING_RUN+=("$tpl")
          msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $tpl"
          themed_count=$((themed_count + 1))
        fi
      done

      msg --padding "0 0 0 $PADDING_LEFT" "Linked $themed_count themed template(s)."
    else
      msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped themed template linking."
    fi
  fi

  echo
fi

# === THEMES (opencode) ===
OPENCODE_THEMES_SOURCE="$DOTFILES_DIR/themes/opencode"
OPENCODE_THEMES_TARGET="$XDG_CONFIG_HOME/opencode/themes"

if [[ -d "$OPENCODE_THEMES_SOURCE" ]]; then
  msg --bold --padding "1 0 0 $PADDING_LEFT" "Themes (opencode):"

  mkdir -p "$OPENCODE_THEMES_TARGET"

  oc_theme_existing=()
  oc_theme_missing=()
  oc_theme_broken=()
  oc_theme_conflicts=()

  for theme_file in "$OPENCODE_THEMES_SOURCE"/*.json; do
    [[ -f "$theme_file" ]] || continue
    theme_name=$(basename "$theme_file")
    target="$OPENCODE_THEMES_TARGET/$theme_name"

    if check_symlink "$theme_file" "$target"; then
      result=0
    else
      result=$?
    fi

    case $result in
      0) oc_theme_existing+=("$theme_name") ;;
      1) oc_theme_missing+=("$theme_name") ;;
      2) oc_theme_broken+=("$theme_name") ;;
      3) oc_theme_conflicts+=("$theme_name") ;;
    esac
  done

  if [[ ${#oc_theme_existing[@]} -gt 0 ]]; then
    msg_color 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#oc_theme_existing[@]}):"
    for theme in "${oc_theme_existing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#oc_theme_conflicts[@]} -gt 0 ]]; then
    msg_color 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#oc_theme_conflicts[@]}):"
    for theme in "${oc_theme_conflicts[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#oc_theme_missing[@]} -gt 0 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#oc_theme_missing[@]}):"
    for theme in "${oc_theme_missing[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#oc_theme_broken[@]} -gt 0 ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#oc_theme_broken[@]}):"
    for theme in "${oc_theme_broken[@]}"; do
      msg --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  echo

  if [[ ${#oc_theme_missing[@]} -gt 0 ]] || [[ ${#oc_theme_broken[@]} -gt 0 ]]; then
    if confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link themes" --negative "Skip"; then
      oc_theme_count=0

      for theme in "${oc_theme_missing[@]}" "${oc_theme_broken[@]}"; do
        source_path="$OPENCODE_THEMES_SOURCE/$theme"
        target_path="$OPENCODE_THEMES_TARGET/$theme"

        if dry_run_guard "Would link opencode theme $theme"; then
          if [[ -L "$target_path" ]]; then
            rm "$target_path"
          fi

          ln -s "$source_path" "$target_path"
          _LINKED_DURING_RUN+=("$theme")
          msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $theme"
          oc_theme_count=$((oc_theme_count + 1))
        fi
      done

      msg --padding "0 0 0 $PADDING_LEFT" "Linked $oc_theme_count theme(s)."
    else
      msg_color 8 --padding "0 0 0 $PADDING_LEFT" "Skipped theme linking."
    fi
  fi

  echo
fi
fi

# === TOP-LEVEL DOTFILES ===
# Link top-level dotfiles from the repo into their machine locations.
link_dotfile() {
  local source_path="$1" target_path="$2"
  [[ -e "$source_path" ]] || return 0

  if check_symlink "$source_path" "$target_path"; then
    local result=0
  else
    local result=$?
  fi

  if [[ $result -eq 0 ]]; then
    msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  $(basename "$source_path") already linked"
  elif [[ $result -eq 1 ]]; then
    if dry_run_guard "Would link $(basename "$source_path")"; then
      ln -s "$source_path" "$target_path"
      msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $(basename "$source_path") → $target_path"
    fi
  elif [[ $result -eq 2 ]]; then
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  $(basename "$source_path") link broken; relinking"
    if dry_run_guard "Would relink $(basename "$source_path")"; then
      rm -f "$target_path"
      ln -s "$source_path" "$target_path"
    fi
  elif [[ $result -eq 3 ]]; then
    msg_color 1 --padding "0 0 0 $PADDING_LEFT" "  $(basename "$source_path") exists (not a link) — skipping"
  fi
}

link_dotfile "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
link_dotfile "$DOTFILES_DIR/AGENTS.md" "$XDG_CONFIG_HOME/AGENTS.md"
echo

# === DEPENDENCIES ===
if [[ $LINK_ONLY -eq 0 ]]; then
deps=(
  "oh-my-posh:oh-my-posh"
  "aliae:aliae"
  "zoxide:zoxide"
  "lsd:lsd"
  "zinit:zinit"
  "fzf:fzf"
  "glow:glow"
  "yt-dlp:yt-dlp"
  "jfsh:jfsh"
  "yazi:yazi"
  "spf:superfile"
  "dunst:dunst"
  "zathura:zathura"
)

msg --bold --padding "1 0 0 $PADDING_LEFT" "Dependencies:"
missing=()
for entry in "${deps[@]}"; do
  cmd="${entry%%:*}"
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("${entry##*:}")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  msg_color 3 --padding "0 0 0 $PADDING_LEFT" "Missing (${#missing[@]}): ${missing[*]}"
  if [[ $DRY_RUN -eq 1 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "(dry-run) Would install: ${missing[*]}"
  elif confirm --padding "0 0 0 $PADDING_LEFT" "Install missing tools?"; then
    yay -S --noconfirm "${missing[@]}" || msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  Some packages failed to install"
  fi
else
  msg_color 2 --padding "0 0 0 $PADDING_LEFT" "All tools already installed."
fi

echo
fi

# === YAZI PACKAGES ===
if [[ $LINK_ONLY -eq 0 ]] && command -v ya &>/dev/null && [[ -f "$XDG_CONFIG_HOME/yazi/package.toml" ]]; then
  msg --bold --padding "1 0 0 $PADDING_LEFT" "Yazi packages:"
  if [[ $DRY_RUN -eq 1 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "(dry-run) Would install yazi packages from package.toml"
  elif ya pkg install 2>&1 | (if [[ $HAS_GUM -eq 1 ]]; then gum style --padding "0 0 0 $PADDING_LEFT" --foreground 8; else cat; fi); then
    msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Yazi packages installed"
  else
    msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  Yazi package install failed — run 'ya pkg install' manually"
  fi
  echo
fi

# === POST-INSTALL VERIFICATION ===
if [[ $DRY_RUN -eq 0 ]]; then
  msg --bold --padding "1 0 0 $PADDING_LEFT" "Verification:"
  verify_ok=0
  verify_fail=0

  # Check all symlinks in ~/.config that point to our dotfiles
  for app_dir in "$CONFIG_DIR"/*; do
    [[ -d "$app_dir" ]] || continue
    app_name=$(basename "$app_dir")
    target="$XDG_CONFIG_HOME/$app_name"

    is_skip "$app_name" && continue
    is_omarchy_managed "$app_name" && continue

    if [[ -L "$target" ]]; then
      link_target=$(readlink "$target")
      if [[ -e "$target" ]]; then
        msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  $app_name: OK"
        verify_ok=$((verify_ok + 1))
      else
        msg_color 1 --padding "0 0 0 $PADDING_LEFT" "  $app_name: BROKEN → $link_target"
        verify_fail=$((verify_fail + 1))
      fi
    fi
  done

  # Check critical tools
  for tool in oh-my-posh zoxide zinit; do
    if command -v "$tool" &>/dev/null; then
      msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  $tool: installed"
    else
      msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  $tool: NOT found"
    fi
  done

  if [[ $verify_fail -gt 0 ]]; then
    msg_color 1 --padding "1 0 0 $PADDING_LEFT" "  $verify_fail broken symlink(s) detected!"
  else
    msg_color 2 --padding "1 0 0 $PADDING_LEFT" "  All $verify_ok symlink(s) valid."
  fi
  echo
fi

# === TRIGGER INITIAL THEME-SET (if omarchy is present) ===
# This regenerates per-theme files (kitty-tab-colors.conf, dunst/dunstrc,
# vicinae/themes/kuroi.toml) so they're in sync with the linked theme.
if [[ $LINK_ONLY -eq 0 ]] && [[ -d "$HOME/.local/share/omarchy" ]] && command -v omarchy-theme-set &>/dev/null; then
  echo
  if [[ $DRY_RUN -eq 1 ]]; then
    msg_color 8 --padding "0 0 0 $PADDING_LEFT" "(dry-run) Would run 'omarchy theme-set kuroi'"
  elif confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --affirmative "Set kuroi" --negative "Skip" "Run 'omarchy theme-set kuroi' to generate per-theme files?"; then
    if omarchy-theme-set kuroi 2>&1 | (if [[ $HAS_GUM -eq 1 ]]; then gum style --padding "0 0 0 $PADDING_LEFT" --foreground 8; else cat; fi); then
      msg_color 2 --padding "0 0 0 $PADDING_LEFT" "  Theme kuroi applied"
    else
      msg_color 3 --padding "0 0 0 $PADDING_LEFT" "  Theme-set failed — run 'omarchy theme-set kuroi' manually"
    fi
  fi
fi

# Done
clear_logo
msg_color 2 --bold --padding "1 0 0 $PADDING_LEFT" "Bootstrap complete!"
msg --padding "1 0 0 $PADDING_LEFT" "Config directories and themes have been linked."
msg --padding "1 0 0 $PADDING_LEFT" "See the README for manual config steps."
