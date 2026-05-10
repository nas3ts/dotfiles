#!/bin/bash

get_mpd_info() {
  mpd_output=$(echo -e "status\ncurrentsong\nclose\n" | nc -U "$XDG_RUNTIME_DIR/mpd/socket" 2>/dev/null)
  if echo "$mpd_output" | grep -q "state: play"; then
    title=$(echo "$mpd_output" | grep -i "^Title:" | head -1 | cut -d':' -f2- | sed 's/^ //')
    artist=$(echo "$mpd_output" | grep -i "^Artist:" | head -1 | cut -d':' -f2- | sed 's/^ //')
    album=$(echo "$mpd_output" | grep -i "^Album:" | head -1 | cut -d':' -f2- | sed 's/^ //')
    echo "mpd"
    return
  fi
  echo ""
}

get_mpris_info() {
  track=$(playerctl metadata --format '{{title}}' 2>/dev/null)
  artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
  player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)
  echo "$track"
}

mpd_source=$(get_mpd_info)

if [[ "$mpd_source" == "mpd" ]]; then
  mpd_output=$(echo -e "status\ncurrentsong\nclose\n" | nc -U "$XDG_RUNTIME_DIR/mpd/socket" 2>/dev/null)
  title=$(echo "$mpd_output" | grep -i "^Title:" | head -1 | cut -d':' -f2- | sed 's/^ //')
  artist=$(echo "$mpd_output" | grep -i "^Artist:" | head -1 | cut -d':' -f2- | sed 's/^ //')
  album=$(echo "$mpd_output" | grep -i "^Album:" | head -1 | cut -d':' -f2- | sed 's/^ //')

  if [[ -n "$title" ]]; then
    tooltip="Now Playing (MPD)"
    [[ -n "$artist" ]] && tooltip="$tooltip\nArtist: $artist"
    [[ -n "$album" ]] && tooltip="$tooltip\nAlbum: $album"
    echo '{"text": "󰝚  '"$title"'", "tooltip": "'"$tooltip"'", "class": "active"}'
  else
    echo ''
  fi
else
  track=$(get_mpris_info)
  artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
  album=$(playerctl metadata --format '{{album}}' 2>/dev/null)
  player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

  if [[ -n "$track" ]]; then
    tooltip="Now Playing"
    [[ -n "$artist" ]] && tooltip="$tooltip\nArtist: $artist"
    [[ -n "$album" ]] && tooltip="$tooltip\nAlbum: $album"
    [[ -n "$player" ]] && tooltip="$tooltip\nPlayer: $player"
    echo '{"text": "󰝚  '"$track"'", "tooltip": "'"$tooltip"'", "class": "active"}'
  else
    echo ''
  fi
fi
