# --- Custom functions/aliae ---
# Credentials are loaded from ~/.local/share/dotfiles-secrets/env.sh
# (created by install.sh, chmod 600, gitignored). If unset, the affected
# functions error with "parameter not set or null" pointing to the
# missing variable name.
[[ -f "$HOME/.local/share/dotfiles-secrets/env.sh" ]] && source "$HOME/.local/share/dotfiles-secrets/env.sh"

function ytm() {
	local url="$1"

	yt-dlp "$url" \
    -x --audio-format mp3 \
    --audio-quality 0 -f bestaudio -o "%(title)s.%(ext)s" \
    --embed-thumbnail \
    --convert-thumbnail jpg \
    --ppa "ThumbnailsConvertor+FFmpeg_o:-c:v mjpeg -qmin 1 -qscale:v 1 -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw')\"" \
    --add-metadata \
    --embed-metadata \
    --parse-metadata "playlist_index:%(track_number)s" \
    --windows-filenames \
    --download-archive archive.txt \
    --no-overwrites

}

function qti() {
  tewi \
    --client-type qbittorrent \
    --host zimaos \
    --port 8181 \
    --username admin \
    --password "${QBIT_ZIMA_PASS:?QBIT_ZIMA_PASS not set — populate ~/.local/share/dotfiles-secrets/env.sh}" \
    --view-mode oneline
}

function qui() {
  tewi \
    --client-type qbittorrent \
    --port 8080 \
    --username nas3ts \
    --password "${QBIT_LOCAL_PASS:?QBIT_LOCAL_PASS not set — populate ~/.local/share/dotfiles-secrets/env.sh}" \
    --view-mode oneline
}
