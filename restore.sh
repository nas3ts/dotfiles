#!/bin/bash
set -euo pipefail

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$XDG_CONFIG_HOME/.backup"

HAS_GUM=0
command -v gum &>/dev/null && HAS_GUM=1

msg() {
  if [[ $HAS_GUM -eq 1 ]]; then
    gum style "$@"
  else
    local color=""
    for ((i=0; i<${#}; i++)); do
      case "${!i}" in
        --foreground) color="${!((i+1))}"; ((i++)) ;;
      esac
    done
    echo "${*: -1}"
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

if [[ ! -d "$BACKUP_DIR" ]]; then
  msg --foreground 3 "No backups found in $BACKUP_DIR"
  exit 0
fi

backups=("$BACKUP_DIR"/*)
[[ "${backups[0]}" == "$BACKUP_DIR/*" ]] && { msg --foreground 3 "No backups found."; exit 0; }

msg --bold --foreground 2 "Restore backups from $BACKUP_DIR:"
for i in "${!backups[@]}"; do
  name=$(basename "${backups[$i]}")
  app="${name%%.*}"
  ts="${name#*.}"
  msg --padding "0 0 0 2" "  $((i+1))) $app ($ts)"
done

if [[ $HAS_GUM -eq 1 ]]; then
  choice=$(gum input --prompt "> " --placeholder "Numbers (e.g. 1,3), 'a' for all, 'n' to skip")
else
  read -r -p "> " choice
fi

selected=()
case "${choice,,}" in
  a|all)
    selected=("${backups[@]}")
    ;;
  n|none|"")
    msg --foreground 8 "Skipped."
    exit 0
    ;;
  *)
    IFS=',' read -ra parts <<< "$choice"
    for part in "${parts[@]}"; do
      part="${part// /}"
      idx=$((part - 1))
      [[ $idx -ge 0 && $idx -lt ${#backups[@]} ]] && selected+=("${backups[$idx]}")
    done
    ;;
esac

for backup in "${selected[@]}"; do
  name=$(basename "$backup")
  app="${name%%.*}"
  target="$XDG_CONFIG_HOME/$app"

  # Backup current state before restoring (safety net)
  if [[ -e "$target" || -L "$target" ]]; then
    pre_restore_ts=$(date +%Y%m%d-%H%M%S)
    if [[ -L "$target" ]]; then
      cp -a "$target" "$BACKUP_DIR/$app.pre-restore.$pre_restore_ts"
    else
      cp -a "$target" "$BACKUP_DIR/$app.pre-restore.$pre_restore_ts"
    fi
    msg --foreground 3 "  Saved current $app → .backup/$app.pre-restore.$pre_restore_ts"
  fi

  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -e "$target" ]]; then
    msg --foreground 3 "  $target exists — skipping $app"
    continue
  fi

  mv "$backup" "$target"
  msg --foreground 2 "  Restored $app"
done

echo
msg --foreground 2 --bold "Restore complete!"
