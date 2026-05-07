#!/bin/bash

if dunstctl get-pause-level | grep -q '0'; then
  echo '{"text": ""}'
else
  echo '{"text": "", "tooltop": "DND Active", "class": "inactive"}'
fi
