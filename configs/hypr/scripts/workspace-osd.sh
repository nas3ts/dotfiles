#!/bin/bash

SOCKET="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

if [ ! -S "$SOCKET" ]; then
  exit 1
fi

socat -u "UNIX-CONNECT:$SOCKET" - 2>/dev/null | while IFS= read -r line; do
  case "$line" in
    workspace\>\>*)
      name="${line#workspace>>}"
      swayosd-client --custom-message "workspace ($name)"
      ;;
  esac
done
