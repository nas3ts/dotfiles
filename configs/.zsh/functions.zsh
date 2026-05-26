# --- Custom functions/aliae ---
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
    --password ***REMOVED*** \
    --view-mode oneline
}

function qui() {
  tewi \
    --client-type qbittorrent \
    --port 8080 \
    --username nas3ts \
    --password ***REMOVED*** \
    --view-mode oneline
}
