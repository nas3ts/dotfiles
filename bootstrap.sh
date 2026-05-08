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

# Terminal sizing (from omarchy)
TERM_WIDTH=80
TERM_HEIGHT=24

if [[ -e /dev/tty ]]; then
  TERM_SIZE=$(stty size 2>/dev/null </dev/tty) && {
    TERM_HEIGHT=$(echo "$TERM_SIZE" | cut -d' ' -f1)
    TERM_WIDTH=$(echo "$TERM_SIZE" | cut -d' ' -f2)
  }
fi

LOGO_PATH="$DOTFILES_DIR/bootstrap-logo.txt"
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

# Find configs that need symlinking
missing_links=()
broken_links=()
existing_links=()
conflicting=()

# Skip folders that shouldn't be symlinked
skip_dirs=("omarchy")
is_skip() {
  for skip in "${skip_dirs[@]}"; do
    [[ "$1" == "$skip" ]] && return 0
  done
  return 1
}

for app_dir in "$CONFIG_DIR"/*; do
  [[ -d "$app_dir" ]] || continue
  app_name=$(basename "$app_dir")
  target="$XDG_CONFIG_HOME/$app_name"

  is_skip "$app_name" && continue

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

echo

# === THEMES (omarchy) ===
OMARCHY_THEMES_SOURCE="$CONFIG_DIR/omarchy/themes"
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

# Done
clear_logo
gum style --foreground 2 --bold --padding "1 0 0 $PADDING_LEFT" "Bootstrap complete!"
gum style --padding "1 0 0 $PADDING_LEFT" "Config directories and themes have been linked."
gum style --padding "1 0 0 $PADDING_LEFT" "See the README for manual config steps."