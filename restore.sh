#!/bin/bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$XDG_CONFIG_HOME/.backup"

if ! command -v gum &>/dev/null; then
  echo "Error: gum is required for restore mode."
  exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  gum style --foreground 3 "No backups found in $BACKUP_DIR"
  exit 0
fi

backups=("$BACKUP_DIR"/*)
[[ "${backups[0]}" == "$BACKUP_DIR/*" ]] && { gum style --foreground 3 "No backups found."; exit 0; }

gum style --bold --foreground 2 "Restore backups from $BACKUP_DIR:"
for i in "${!backups[@]}"; do
  name=$(basename "${backups[$i]}")
  app="${name%.*}"
  ts="${name##*.}"
  gum style --padding "0 0 0 2" "  $((i+1))) $app ($ts)"
done

choice=$(gum input --prompt "> " --placeholder "Numbers (e.g. 1,3), 'a' for all, 'n' to skip")

selected=()
case "${choice,,}" in
  a|all)
    selected=("${backups[@]}")
    ;;
  n|none|"")
    gum style --foreground 8 "Skipped."
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
  app="${name%.*}"
  target="$XDG_CONFIG_HOME/$app"

  if [[ -L "$target" ]]; then
    rm "$target"
  elif [[ -e "$target" ]]; then
    gum style --foreground 3 "  $target exists — skipping $app"
    continue
  fi

  mv "$backup" "$target"
  gum style --foreground 2 "  Restored $app"
done
