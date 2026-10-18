#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/output"
OUT="$OUT_DIR/stickman-short.mp4"
mkdir -p "$OUT_DIR"
for tool in ffmpeg ffprobe; do
  command -v "$tool" >/dev/null 2>&1 || { echo "FAIL: $tool missing. Install: pkg install ffmpeg" >&2; exit 1; }
done

# First procedural stickman prototype. Draw each limb as a small overlay layer
# so movement uses the verified overlay timestamp expression rather than
# drawbox x/y expressions. This is vector-style animation, not AI video.
ffmpeg -y -hide_banner -loglevel warning \
  -f lavfi -i "color=c=0x10162f:s=720x1280:r=24:d=10" \
  -f lavfi -i "color=c=0x32d6c5:s=76x76:r=24:d=10" \
  -f lavfi -i "color=c=white:s=16x230:r=24:d=10" \
  -f lavfi -i "color=c=white:s=14x170:r=24:d=10" \
  -f lavfi -i "color=c=white:s=14x170:r=24:d=10" \
  -f lavfi -i "color=c=white:s=14x170:r=24:d=10" \
  -f lavfi -i "color=c=white:s=14x170:r=24:d=10" \
  -f lavfi -i "color=c=white:s=14x170:r=24:d=10" \
  -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=10" \
  -filter_complex "[0:v][1:v]overlay=x='max(40,min(604,40+t*56))':y='350+abs(sin(t*6))*12'[a];[a][2:v]overlay=x='x'+31:y=426[b];[b][3:v]overlay=x='max(0,min(706,40+t*56))+5+20*sin(t*6)':y='600+20*sin(t*6)'[c];[c][4:v]overlay=x='max(0,min(706,40+t*56))+5-20*sin(t*6)':y='600-20*sin(t*6)'[d];[d][5:v]overlay=x='max(0,min(706,40+t*56))+5+25*sin(t*6+PI)':y='760+35*abs(sin(t*6))'[e];[e][6:v]overlay=x='max(0,min(706,40+t*56))+5-25*sin(t*6+PI)':y='760+35*abs(sin(t*6+PI))'[f];[f][7:v]overlay=x='max(0,min(706,40+t*56))+5':y=600[g];[g]null[v]" \
  -map "[v]" -map 8:a:0 -t 10 -r 24 -c:v libx264 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart "$OUT"

DURATION="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")"
WIDTH="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")"
HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OUT")"
AUDIO="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$OUT")"
[ "$WIDTH" = 720 ] && [ "$HEIGHT" = 1280 ] || { echo "FAIL: dimensions ${WIDTH}x${HEIGHT}"; exit 1; }
awk -v d="$DURATION" 'BEGIN { exit !(d >= 9.8 && d <= 10.3) }' || { echo "FAIL: duration $DURATION"; exit 1; }
[ -n "$AUDIO" ] || { echo "FAIL: audio missing"; exit 1; }
HASH_A="$(ffmpeg -v error -ss 1 -i "$OUT" -frames:v 1 -f framemd5 - 2>/dev/null | awk -F', ' '/^[0-9]+,/ {h=$NF} END {print h}')"
HASH_B="$(ffmpeg -v error -ss 8 -i "$OUT" -frames:v 1 -f framemd5 - 2>/dev/null | awk -F', ' '/^[0-9]+,/ {h=$NF} END {print h}')"
[ -n "$HASH_A" ] && [ "$HASH_A" != "$HASH_B" ] || { echo "FAIL: sampled frames did not change"; exit 1; }
echo "PASS: stickman prototype rendered; metadata and frame-change checks passed"
echo "Duration: $DURATION s | Resolution: ${WIDTH}x${HEIGHT} | Audio: $AUDIO"
echo "NOTE: inspect frames for visual quality; this is a primitive procedural prototype."
echo "Output: $OUT"
