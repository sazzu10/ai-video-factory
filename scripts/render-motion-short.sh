#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/output"
OUT="$OUT_DIR/motion-short.mp4"
mkdir -p "$OUT_DIR"

for tool in ffmpeg ffprobe; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "FAIL: $tool is missing. Install with: pkg install ffmpeg" >&2
    exit 1
  fi
done

# Render moving layers with overlay (verified on the user's FFmpeg build).
# Avoid drawtext and avoid drawbox position expressions.
ffmpeg -y -hide_banner -loglevel warning \
  -f lavfi -i "color=c=0x10162f:s=720x1280:r=24:d=10" \
  -f lavfi -i "color=c=0x32d6c5:s=180x180:r=24:d=10" \
  -f lavfi -i "color=c=0xffc857:s=140x140:r=24:d=10" \
  -f lavfi -i "color=c=white:s=640x12:r=24:d=10" \
  -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=10" \
  -filter_complex "[0:v][1:v]overlay=x='max(0,min(540,t*55))':y=230:shortest=1[v1];[v1][2:v]overlay=x='max(0,min(580,700-t*40))':y=850:shortest=1[v2];[v2][3:v]overlay=x=40:y='mod(t*100,1200)':shortest=1[v]" \
  -map "[v]" -map 4:a:0 -t 10 -r 24 -c:v libx264 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart "$OUT"

DURATION="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")"
WIDTH="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")"
HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OUT")"
AUDIO="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$OUT")"
[ "$WIDTH" = "720" ] && [ "$HEIGHT" = "1280" ] || { echo "FAIL: dimensions ${WIDTH}x${HEIGHT}"; exit 1; }
awk -v d="$DURATION" 'BEGIN { exit !(d >= 9.8 && d <= 10.3) }' || { echo "FAIL: duration $DURATION"; exit 1; }
[ -n "$AUDIO" ] || { echo "FAIL: audio missing"; exit 1; }

# Visual-motion gate: compare pixel hashes from two separated timestamps.
HASH_A="$(ffmpeg -v error -ss 1 -i "$OUT" -frames:v 1 -f framemd5 - 2>/dev/null | awk -F', ' '/^[0-9]+,/ {h=$NF} END {print h}')"
HASH_B="$(ffmpeg -v error -ss 8 -i "$OUT" -frames:v 1 -f framemd5 - 2>/dev/null | awk -F', ' '/^[0-9]+,/ {h=$NF} END {print h}')"
[ -n "$HASH_A" ] && [ -n "$HASH_B" ] || { echo "FAIL: could not verify frame hashes"; exit 1; }
[ "$HASH_A" != "$HASH_B" ] || { echo "FAIL: sampled frames are identical; motion not detected"; exit 1; }

echo "PASS: motion-graphics Short rendered and frame-change check passed"
echo "Duration: $DURATION s | Resolution: ${WIDTH}x${HEIGHT} | Audio: $AUDIO"
echo "Frame hash 1s: $HASH_A"
echo "Frame hash 8s: $HASH_B"
echo "Output: $OUT"
