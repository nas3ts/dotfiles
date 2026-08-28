#!/bin/bash

DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$DOTFILES_DIR/configs"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"

check_symlink() {
  local source="$1"
  local target="$2"

  if [[ -L "$target" ]]; then
    local link_target=$(readlink "$target")
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

# Ensure gum is available
if ! command -v gum &>/dev/null; then
  gum style --foreground 3 "Installing gum..."
  if command -v yay &>/dev/null; then
    yay -S gum --noconfirm
  else
    gum style --foreground 1 "Error: gum is required but not installed. Install it first."
    exit 1
  fi
fi

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
  TERM_SIZE=$(stty size 2>/dev/null </dev/tty) && {
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
  gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "$(<"$LOGO_PATH")"
}

# Intro
clear_logo
gum style --padding "1 0 0 $PADDING_LEFT" "Welcome to dotfiles bootstrap!"
gum style --foreground 8 --padding "1 0 0 $PADDING_LEFT" "This will link your config directories."
echo

# Show preflight warnings
if [[ ${#preflight_warnings[@]} -gt 0 ]]; then
  gum style --bold --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Pre-flight warnings:"
  for w in "${preflight_warnings[@]}"; do
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "  ! $w"
  done
  echo
fi

# === AUTO-SOURCE .ZSHRC ===
# Ensures the user's ~/.zshrc picks up dotfiles/.zshrc, so a fresh install works
# without manual symlinking.
ZSHRC_TARGET="$HOME/.zshrc"
ZSHRC_SOURCE_LINE="source $DOTFILES_DIR/.zshrc"

if [[ ! -f "$DOTFILES_DIR/.zshrc" ]]; then
  gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Skipped zshrc: $DOTFILES_DIR/.zshrc not found"
else
  zshrc_already_sources=false
  if [[ -f "$ZSHRC_TARGET" ]] && grep -qF "$ZSHRC_SOURCE_LINE" "$ZSHRC_TARGET" 2>/dev/null; then
    zshrc_already_sources=true
  fi

  if $zshrc_already_sources; then
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "~/.zshrc already sources dotfiles"
  else
    if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --affirmative "Add source line" --negative "Skip" "Add 'source $ZSHRC_SOURCE_LINE' to ~/.zshrc?"; then
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
      gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Added source line to ~/.zshrc"
    else
      gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped zshrc. Run manually: ln -s $DOTFILES_DIR/.zshrc ~/.zshrc"
    fi
  fi
  echo
fi

# === SECRETS FILE ===
# The repo's per-user secret files (configs/.zsh/functions.zsh,
# configs/managarr/config.yml) reference env vars defined in a separate
# runtime file. This file is gitignored, chmod 600, and sourced from the
# sanitized functions.zsh.
SECRETS_DIR="$HOME/.local/share/dotfiles-secrets"
SECRETS_FILE="$SECRETS_DIR/env.sh"

if [[ -f "$SECRETS_FILE" ]]; then
  perms=$(stat -c '%a' "$SECRETS_FILE" 2>/dev/null || stat -f '%A' "$SECRETS_FILE" 2>/dev/null)
  if [[ "$perms" != "600" ]]; then
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "  ! $SECRETS_FILE exists but is mode $perms (expected 600), tightening"
    chmod 600 "$SECRETS_FILE"
  else
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Secrets file present: $SECRETS_FILE (mode 600)"
  fi
else
  if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --affirmative "Create" --negative "Skip" "Create secrets file at $SECRETS_FILE?"; then
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
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Created $SECRETS_FILE (mode 600) — populate before using qti/qui/managarr"
  else
    gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "  Skipped secrets file. functions.zsh and managarr will fail until you create $SECRETS_FILE"
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
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "  Skipped $app_name (omarchy-managed; would conflict with built-in config)"
    continue
  fi

  check_symlink "$app_dir" "$target"
  result=$?

  case $result in
    0) existing_links+=("$app_name") ;;
    1) missing_links+=("$app_name") ;;
    2) broken_links+=("$app_name") ;;
    3) conflicting+=("$app_name") ;;
  esac
done

# Show symlink status
if [[ ${#existing_links[@]} -gt 0 ]]; then
  gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "Already linked (${#existing_links[@]}):"
  for app in "${existing_links[@]}"; do
    gum style --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

if [[ ${#broken_links[@]} -gt 0 ]]; then
  gum style --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Broken links (${#broken_links[@]}):"
  for app in "${broken_links[@]}"; do
    gum style --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

if [[ ${#conflicting[@]} -gt 0 ]]; then
  gum style --foreground 1 --padding "1 0 0 $PADDING_LEFT" "Conflicts (already exist, not symlinked) (${#conflicting[@]}):"
  for app in "${conflicting[@]}"; do
    gum style --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

if [[ ${#missing_links[@]} -gt 0 ]]; then
  gum style --foreground 8 --padding "1 0 0 $PADDING_LEFT" "Need linking (${#missing_links[@]}):"
  for app in "${missing_links[@]}"; do
    gum style --padding "0 0 0 $PADDING_LEFT" "  $app"
  done
fi

echo

# Ask about symlinking
if [[ ${#missing_links[@]} -gt 0 ]] || [[ ${#broken_links[@]} -gt 0 ]]; then
  if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link configs" --negative "Skip"; then
    symlink_count=0

    for app in "${missing_links[@]}" "${broken_links[@]}"; do
      source_path="$CONFIG_DIR/$app"
      target_path="$XDG_CONFIG_HOME/$app"

      if [[ -L "$target_path" ]]; then
        rm "$target_path"
      fi

      ln -s "$source_path" "$target_path"
      gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $app"
      symlink_count=$((symlink_count + 1))
    done

    gum style --padding "1 0 0 $PADDING_LEFT" "Linked $symlink_count config(s)."
  else
    gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped symlinking."
  fi
fi

# === CONFLICT HANDLING ===
if [[ ${#conflicting[@]} -gt 0 ]]; then
  BACKUP_DIR="$XDG_CONFIG_HOME/.backup"
  echo
  gum style --bold --foreground 3 --padding "1 0 0 $PADDING_LEFT" "Conflicting configs (${#conflicting[@]}):"
  for i in "${!conflicting[@]}"; do
    gum style --padding "0 0 0 $PADDING_LEFT" "  $((i+1))) ${conflicting[$i]}"
  done
  gum style --padding "0 0 0 $PADDING_LEFT" ""

  choice=$(gum input --prompt "> " --placeholder "Numbers (e.g. 1,3), 'a' for all, 'n' to skip")

  selected=()
  case "${choice,,}" in
    a|all)
      selected=("${conflicting[@]}")
      ;;
    n|none|"")
      gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped all conflicts."
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

  if [[ ${#selected[@]} -gt 0 ]]; then
    for app in "${selected[@]}"; do
      source_path="$CONFIG_DIR/$app"
      target_path="$XDG_CONFIG_HOME/$app"
      timestamp=$(date +%Y%m%d-%H%M%S)
      mkdir -p "$BACKUP_DIR"
      mv "$target_path" "$BACKUP_DIR/$app.$timestamp"
      ln -s "$source_path" "$target_path"
      gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Backed up $app → .backup/$app.$timestamp & linked"
    done
    gum style --foreground 2 --padding "1 0 0 $PADDING_LEFT" "Linked ${#selected[@]} conflict(s)."
  fi
fi

echo

# === THEMES (omarchy) ===
OMARCHY_THEMES_SOURCE="$DOTFILES_DIR/themes/omarchy"
OMARCHY_THEMES_TARGET="$XDG_CONFIG_HOME/omarchy/themes"

if [[ -d "$OMARCHY_THEMES_SOURCE" ]]; then
  gum style --bold --padding "1 0 0 $PADDING_LEFT" "Themes (omarchy):"

  theme_existing=()
  theme_missing=()
  theme_broken=()
  theme_conflicts=()

  for theme_dir in "$OMARCHY_THEMES_SOURCE"/*; do
    [[ -d "$theme_dir" ]] || continue
    theme_name=$(basename "$theme_dir")
    target="$OMARCHY_THEMES_TARGET/$theme_name"

    check_symlink "$theme_dir" "$target"
    result=$?

    case $result in
      0) theme_existing+=("$theme_name") ;;
      1) theme_missing+=("$theme_name") ;;
      2) theme_broken+=("$theme_name") ;;
      3) theme_conflicts+=("$theme_name") ;;
    esac
  done

  if [[ ${#theme_existing[@]} -gt 0 ]]; then
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#theme_existing[@]}):"
    for theme in "${theme_existing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#theme_conflicts[@]} -gt 0 ]]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#theme_conflicts[@]}):"
    for theme in "${theme_conflicts[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#theme_missing[@]} -gt 0 ]]; then
    gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#theme_missing[@]}):"
    for theme in "${theme_missing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#theme_broken[@]} -gt 0 ]]; then
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#theme_broken[@]}):"
    for theme in "${theme_broken[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  echo

  if [[ ${#theme_missing[@]} -gt 0 ]] || [[ ${#theme_broken[@]} -gt 0 ]]; then
    if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link themes" --negative "Skip"; then
      theme_count=0

      for theme in "${theme_missing[@]}" "${theme_broken[@]}"; do
        source_path="$OMARCHY_THEMES_SOURCE/$theme"
        target_path="$OMARCHY_THEMES_TARGET/$theme"

        if [[ -L "$target_path" ]]; then
          rm "$target_path"
        fi

        ln -s "$source_path" "$target_path"
        gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $theme"
        theme_count=$((theme_count + 1))
      done

      gum style --padding "0 0 0 $PADDING_LEFT" "Linked $theme_count theme(s)."
    else
      gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped theme linking."
    fi
  fi

  echo
fi

# === OMARCHY HOOKS ===
OMARCHY_HOOKS_SOURCE="$DOTFILES_DIR/configs/omarchy/hooks"
OMARCHY_HOOKS_TARGET="$XDG_CONFIG_HOME/omarchy/hooks"

if [[ -d "$OMARCHY_HOOKS_SOURCE" ]]; then
  gum style --bold --padding "1 0 0 $PADDING_LEFT" "Omarchy hooks:"

  hook_existing=()
  hook_missing=()
  hook_broken=()
  hook_conflicts=()

  for hook_file in "$OMARCHY_HOOKS_SOURCE"/*; do
    [[ -f "$hook_file" ]] || continue
    hook_name=$(basename "$hook_file")
    target="$OMARCHY_HOOKS_TARGET/$hook_name"

    check_symlink "$hook_file" "$target"
    result=$?

    case $result in
      0) hook_existing+=("$hook_name") ;;
      1) hook_missing+=("$hook_name") ;;
      2) hook_broken+=("$hook_name") ;;
      3) hook_conflicts+=("$hook_name") ;;
    esac
  done

  if [[ ${#hook_existing[@]} -gt 0 ]]; then
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#hook_existing[@]}):"
    for hook in "${hook_existing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  if [[ ${#hook_conflicts[@]} -gt 0 ]]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#hook_conflicts[@]}):"
    for hook in "${hook_conflicts[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  if [[ ${#hook_missing[@]} -gt 0 ]]; then
    gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#hook_missing[@]}):"
    for hook in "${hook_missing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  if [[ ${#hook_broken[@]} -gt 0 ]]; then
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#hook_broken[@]}):"
    for hook in "${hook_broken[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $hook"
    done
  fi

  echo

  if [[ ${#hook_missing[@]} -gt 0 ]] || [[ ${#hook_broken[@]} -gt 0 ]]; then
    if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link hooks" --negative "Skip"; then
      hook_count=0

      for hook in "${hook_missing[@]}" "${hook_broken[@]}"; do
        source_path="$OMARCHY_HOOKS_SOURCE/$hook"
        target_path="$OMARCHY_HOOKS_TARGET/$hook"

        if [[ -L "$target_path" ]]; then
          rm "$target_path"
        fi

        ln -s "$source_path" "$target_path"
        gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $hook"
        hook_count=$((hook_count + 1))
      done

      gum style --padding "0 0 0 $PADDING_LEFT" "Linked $hook_count hook(s)."
    else
      gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped hook linking."
    fi
  fi

  echo
fi

# === OMARCHY THEMED TEMPLATES ===
OMARCHY_THEMED_SOURCE="$DOTFILES_DIR/configs/omarchy/themed"
OMARCHY_THEMED_TARGET="$XDG_CONFIG_HOME/omarchy/themed"

if [[ -d "$OMARCHY_THEMED_SOURCE" ]]; then
  gum style --bold --padding "1 0 0 $PADDING_LEFT" "Omarchy themed templates:"

  themed_existing=()
  themed_missing=()
  themed_broken=()
  themed_conflicts=()

  for tpl_file in "$OMARCHY_THEMED_SOURCE"/*; do
    [[ -f "$tpl_file" ]] || continue
    tpl_name=$(basename "$tpl_file")
    target="$OMARCHY_THEMED_TARGET/$tpl_name"

    check_symlink "$tpl_file" "$target"
    result=$?

    case $result in
      0) themed_existing+=("$tpl_name") ;;
      1) themed_missing+=("$tpl_name") ;;
      2) themed_broken+=("$tpl_name") ;;
      3) themed_conflicts+=("$tpl_name") ;;
    esac
  done

  if [[ ${#themed_existing[@]} -gt 0 ]]; then
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#themed_existing[@]}):"
    for tpl in "${themed_existing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  if [[ ${#themed_conflicts[@]} -gt 0 ]]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#themed_conflicts[@]}):"
    for tpl in "${themed_conflicts[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  if [[ ${#themed_missing[@]} -gt 0 ]]; then
    gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#themed_missing[@]}):"
    for tpl in "${themed_missing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  if [[ ${#themed_broken[@]} -gt 0 ]]; then
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#themed_broken[@]}):"
    for tpl in "${themed_broken[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $tpl"
    done
  fi

  echo

  if [[ ${#themed_missing[@]} -gt 0 ]] || [[ ${#themed_broken[@]} -gt 0 ]]; then
    if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link themed templates" --negative "Skip"; then
      themed_count=0

      for tpl in "${themed_missing[@]}" "${themed_broken[@]}"; do
        source_path="$OMARCHY_THEMED_SOURCE/$tpl"
        target_path="$OMARCHY_THEMED_TARGET/$tpl"

        if [[ -L "$target_path" ]]; then
          rm "$target_path"
        fi

        ln -s "$source_path" "$target_path"
        gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $tpl"
        themed_count=$((themed_count + 1))
      done

      gum style --padding "0 0 0 $PADDING_LEFT" "Linked $themed_count themed template(s)."
    else
      gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped themed template linking."
    fi
  fi

  echo
fi

# === THEMES (opencode) ===
OPENCODE_THEMES_SOURCE="$DOTFILES_DIR/themes/opencode"
OPENCODE_THEMES_TARGET="$XDG_CONFIG_HOME/opencode/themes"

if [[ -d "$OPENCODE_THEMES_SOURCE" ]]; then
  gum style --bold --padding "1 0 0 $PADDING_LEFT" "Themes (opencode):"

  mkdir -p "$OPENCODE_THEMES_TARGET"

  oc_theme_existing=()
  oc_theme_missing=()
  oc_theme_broken=()
  oc_theme_conflicts=()

  for theme_file in "$OPENCODE_THEMES_SOURCE"/*.json; do
    [[ -f "$theme_file" ]] || continue
    theme_name=$(basename "$theme_file")
    target="$OPENCODE_THEMES_TARGET/$theme_name"

    check_symlink "$theme_file" "$target"
    result=$?

    case $result in
      0) oc_theme_existing+=("$theme_name") ;;
      1) oc_theme_missing+=("$theme_name") ;;
      2) oc_theme_broken+=("$theme_name") ;;
      3) oc_theme_conflicts+=("$theme_name") ;;
    esac
  done

  if [[ ${#oc_theme_existing[@]} -gt 0 ]]; then
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "Already linked (${#oc_theme_existing[@]}):"
    for theme in "${oc_theme_existing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#oc_theme_conflicts[@]} -gt 0 ]]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "Conflicts (${#oc_theme_conflicts[@]}):"
    for theme in "${oc_theme_conflicts[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#oc_theme_missing[@]} -gt 0 ]]; then
    gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Need linking (${#oc_theme_missing[@]}):"
    for theme in "${oc_theme_missing[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  if [[ ${#oc_theme_broken[@]} -gt 0 ]]; then
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Broken links (${#oc_theme_broken[@]}):"
    for theme in "${oc_theme_broken[@]}"; do
      gum style --padding "0 0 0 $PADDING_LEFT" "  $theme"
    done
  fi

  echo

  if [[ ${#oc_theme_missing[@]} -gt 0 ]] || [[ ${#oc_theme_broken[@]} -gt 0 ]]; then
    if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --default --affirmative "Link themes" --negative "Skip"; then
      oc_theme_count=0

      for theme in "${oc_theme_missing[@]}" "${oc_theme_broken[@]}"; do
        source_path="$OPENCODE_THEMES_SOURCE/$theme"
        target_path="$OPENCODE_THEMES_TARGET/$theme"

        if [[ -L "$target_path" ]]; then
          rm "$target_path"
        fi

        ln -s "$source_path" "$target_path"
        gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $theme"
        oc_theme_count=$((oc_theme_count + 1))
      done

      gum style --padding "0 0 0 $PADDING_LEFT" "Linked $oc_theme_count theme(s)."
    else
      gum style --foreground 8 --padding "0 0 0 $PADDING_LEFT" "Skipped theme linking."
    fi
  fi

  echo
fi

# === TOP-LEVEL DOTFILES ===
# Link top-level dotfiles that live directly in $HOME (not under ~/.config).
top_level_links=(".vimrc")
for tl in "${top_level_links[@]}"; do
  source_path="$DOTFILES_DIR/$tl"
  target_path="$HOME/$tl"
  [[ -e "$source_path" ]] || continue

  check_symlink "$source_path" "$target_path"
  result=$?

  if [[ $result -eq 0 ]]; then
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  $tl already linked"
  elif [[ $result -eq 1 ]]; then
    ln -s "$source_path" "$target_path"
    gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Linked $tl → $target_path"
  elif [[ $result -eq 2 ]]; then
    gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "  $tl link broken; relinking"
    rm -f "$target_path"
    ln -s "$source_path" "$target_path"
  elif [[ $result -eq 3 ]]; then
    gum style --foreground 1 --padding "0 0 0 $PADDING_LEFT" "  $tl exists (not a link) — skipping"
  fi
done
echo

# === DEPENDENCIES ===
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

gum style --bold --padding "1 0 0 $PADDING_LEFT" "Dependencies:"
missing=()
for entry in "${deps[@]}"; do
  cmd="${entry%%:*}"
  if ! command -v "$cmd" &>/dev/null; then
    missing+=("${entry##*:}")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "Missing (${#missing[@]}): ${missing[*]}"
  if gum confirm --padding "0 0 0 $PADDING_LEFT" "Install missing tools?"; then
    yay -S --noconfirm "${missing[@]}"
  fi
else
  gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "All tools already installed."
fi

echo

# === TRIGGER INITIAL THEME-SET (if omarchy is present) ===
# This regenerates per-theme files (kitty-tab-colors.conf, dunst/dunstrc,
# vicinae/themes/kuroi.toml) so they're in sync with the linked theme.
if [[ -d "$HOME/.local/share/omarchy" ]] && command -v omarchy-theme-set &>/dev/null; then
  echo
  if gum confirm --padding "0 0 0 $PADDING_LEFT" --show-help=false --affirmative "Set kuroi" --negative "Skip" "Run 'omarchy theme-set kuroi' to generate per-theme files?"; then
    omarchy-theme-set kuroi 2>&1 | gum style --padding "0 0 0 $PADDING_LEFT" --foreground 8
    if [[ $? -eq 0 ]]; then
      gum style --foreground 2 --padding "0 0 0 $PADDING_LEFT" "  Theme kuroi applied"
    else
      gum style --foreground 3 --padding "0 0 0 $PADDING_LEFT" "  Theme-set failed — run 'omarchy theme-set kuroi' manually"
    fi
  fi
fi

# Done
clear_logo
gum style --foreground 2 --bold --padding "1 0 0 $PADDING_LEFT" "Bootstrap complete!"
gum style --padding "1 0 0 $PADDING_LEFT" "Config directories and themes have been linked."
gum style --padding "1 0 0 $PADDING_LEFT" "See the README for manual config steps."
