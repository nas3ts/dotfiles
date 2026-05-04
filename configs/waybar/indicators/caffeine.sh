#!/bin/bash

if pgrep -x hypridle >/dev/null; then
  echo '{"text": "󰛊", "tooltop": "Caffeine Disabled", "class": "inactive"}'
else
  echo '{"text": "󰅶", "tooltip": "Caffeine Enabled", "class": "active"}'
fi
