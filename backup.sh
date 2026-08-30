#!/bin/bash
set -euo pipefail

# backup.sh — Full disaster-recovery snapshot of the dotfiles setup.
# Creates a timestamped tarball containing:
#   - All managed symlinks and their targets
#   - The .config/.backup/ directory
#   - The pre-install snapshot
#   - The secrets file (if present)
#   - A manifest of unmanaged configs in ~/.config/
#
# Usage:
#   backup.sh                  # snapshot to ~/.config/.dotfiles-backup/
#   backup.sh /path/to/dir     # snapshot to a custom directory
#   backup.sh --stdout         # stream tarball to stdout (for piping)

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR="$HOME/.dotfiles"
CONFIG_DIR="$DOTFILES_DIR/configs"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Parse args
BACKUP_DIR="$XDG_CONFIG_HOME/.dotfiles-backup"
STDOUT_MODE=0
for arg in "$@"; do
  case "$arg" in
    --stdout) STDOUT_MODE=1 ;;
    -h|--help)
      echo "Usage: backup.sh [--stdout] [BACKUP_DIR]"
      echo
      echo "Creates a disaster-recovery tarball of all managed dotfiles."
      echo "Default output: ~/.config/.dotfiles-backup/"
      echo "Use --stdout to pipe to stdout instead."
      exit 0
      ;;
    *) BACKUP_DIR="$arg" ;;
  esac
done

HAS_GUM=0
command -v gum &>/dev/null && HAS_GUM=1

msg() {
  if [[ $HAS_GUM -eq 1 ]]; then
    gum style "$@"
  else
    echo "${*: -1}"
  fi
}

# Build a temporary staging directory
STAGE_DIR=$(mktemp -d)
trap 'rm -rf "$STAGE_DIR"' EXIT

msg --bold --foreground 2 "Dotfiles backup — $TIMESTAMP"

# 1. Managed symlinks manifest
mkdir -p "$STAGE_DIR/manifest"
for app_dir in "$CONFIG_DIR"/*; do
  [[ -d "$app_dir" ]] || continue
  app_name=$(basename "$app_dir")
  target="$XDG_CONFIG_HOME/$app_name"

  if [[ -L "$target" ]]; then
    link_target=$(readlink "$target")
    printf "symlink\t%s\t%s\n" "$app_name" "$link_target" >> "$STAGE_DIR/manifest/symlinks.txt"
  elif [[ -e "$target" ]]; then
    printf "file\t%s\n" "$app_name" >> "$STAGE_DIR/manifest/symlinks.txt"
  fi
done

# Top-level dotfiles
[[ -L "$HOME/.vimrc" ]] && printf "symlink\t.vimrc\t%s\n" "$(readlink "$HOME/.vimrc")" >> "$STAGE_DIR/manifest/symlinks.txt"
[[ -L "$XDG_CONFIG_HOME/AGENTS.md" ]] && printf "symlink\tAGENTS.md\t%s\n" "$(readlink "$XDG_CONFIG_HOME/AGENTS.md")" >> "$STAGE_DIR/manifest/symlinks.txt"

msg --foreground 8 "  Manifest: symlinks recorded"

# 2. Snapshot of all managed config dirs (the actual files, not just symlinks)
mkdir -p "$STAGE_DIR/configs"
for app_dir in "$CONFIG_DIR"/*; do
  [[ -d "$app_dir" ]] || continue
  app_name=$(basename "$app_dir")
  # Skip dot-prefixed dirs and large/generated dirs
  [[ "$app_name" == plugins ]] && continue
  cp -a "$app_dir" "$STAGE_DIR/configs/"
done
msg --foreground 8 "  Configs: copied $(ls "$STAGE_DIR/configs" | wc -l) dirs"

# 3. Backup directory (conflict backups, pre-restore backups)
if [[ -d "$XDG_CONFIG_HOME/.backup" ]]; then
  cp -a "$XDG_CONFIG_HOME/.backup" "$STAGE_DIR/conflict-backups"
  msg --foreground 8 "  Conflict backups: copied"
fi

# 4. Pre-install snapshot
if [[ -d "$XDG_CONFIG_HOME/.pre-install-backup" ]]; then
  cp -a "$XDG_CONFIG_HOME/.pre-install-backup" "$STAGE_DIR/pre-install-snapshot"
  msg --foreground 8 "  Pre-install snapshot: copied"
fi

# 5. Secrets file (if present and non-empty)
SECRETS_FILE="$HOME/.local/share/dotfiles-secrets/env.sh"
if [[ -f "$SECRETS_FILE" ]]; then
  mkdir -p "$STAGE_DIR/secrets"
  cp "$SECRETS_FILE" "$STAGE_DIR/secrets/env.sh"
  chmod 600 "$STAGE_DIR/secrets/env.sh"
  msg --foreground 3 "  Secrets: included (ensure this backup is stored securely!)"
else
  msg --foreground 8 "  Secrets: not found, skipping"
fi

# 6. Unmanaged configs manifest (for manual review)
mkdir -p "$STAGE_DIR/unmanaged"
UNMANIFEST="$STAGE_DIR/unmanaged/README.txt"
cat > "$UNMANIFEST" <<'EOF'
# Unmanaged configs in ~/.config/
# These are NOT backed up automatically. Review and back up manually
# if they contain important data.
EOF

for entry in "$XDG_CONFIG_HOME"/*; do
  [[ -e "$entry" ]] || continue
  name=$(basename "$entry")
  [[ "$name" == ".backup" || "$name" == ".pre-install-backup" ]] && continue

  # Check if it's managed by dotfiles
  is_managed=0
  for app_dir in "$CONFIG_DIR"/*; do
    [[ -d "$app_dir" ]] && [[ "$(basename "$app_dir")" == "$name" ]] && { is_managed=1; break; }
  done

  # Check if it's omarchy-managed
  omarchy_managed=("kitty" "hypr" "git" "foot" "ghostty" "alacritty" "tmux" "lazygit" "btop" "obsidian" "imv" "herdr" "wireplumber" "xournalpp" "chromium" "fcitx5")
  for app in "${omarchy_managed[@]}"; do
    [[ "$name" == "$app" ]] && { is_managed=1; break; }
  done

  [[ "$name" == "omarchy" || "$name" == "git" ]] && is_managed=1

  if [[ $is_managed -eq 0 ]]; then
    printf "  %s/\n" "$name" >> "$UNMANIFEST"
  fi
done

msg --foreground 8 "  Unmanaged configs: listed in manifest"

# 7. Build the tarball
TARBALL_NAME="dotfiles-backup-$TIMESTAMP.tar.gz"

if [[ $STDOUT_MODE -eq 1 ]]; then
  tar -czf - -C "$STAGE_DIR" .
  msg --foreground 2 "  Streamed to stdout"
else
  mkdir -p "$BACKUP_DIR"
  tar -czf "$BACKUP_DIR/$TARBALL_NAME" -C "$STAGE_DIR" .
  msg --foreground 2 "  Saved: $BACKUP_DIR/$TARBALL_NAME"

  # Show size
  size=$(du -h "$BACKUP_DIR/$TARBALL_NAME" | cut -f1)
  msg --foreground 8 "  Size: $size"
fi

echo
msg --foreground 2 --bold "Backup complete!"
msg --foreground 3 "IMPORTANT: This backup may contain secrets. Store it securely."
