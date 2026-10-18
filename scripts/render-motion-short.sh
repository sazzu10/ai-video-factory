#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/output"
OUT="$OUT_DIR/motion-short.mp4"
mkdir -p "$OUT_DIR"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "FAIL: ffmpeg is not installed. On Termux, run: pkg install ffmpeg" >&2
  exit 1
fi

# Avoid drawtext/libfreetype because many Android FFmpeg builds omit it.
# This baseline prototype uses frame-varying shapes plus an audio track.
ffmpeg -y -hide_banner -loglevel warning \
  -f lavfi -i "color=c=0x10162f:s=720x1280:r=24:d=10" \
  -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=10" \
  -vf "drawbox=x='t*150-180':y=230:w=180:h=180:color=0x32d6c5@0.95:t=fill,drawbox=x='700-t*100':y=850:w=140:h=140:color=0xffc857@0.95:t=fill,drawbox=x=40:y='mod(t*100,1100)':w=640:h=8:color=white@0.7:t=fill" \
  -map 0:v:0 -map 1:a:0 -t 10 -r 24 -c:v libx264 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart "$OUT"

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "WARN: ffprobe not found; render completed but validation is incomplete."
  echo "Output: $OUT"
  exit 0
fi
DURATION="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")"
WIDTH="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")"
HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OUT")"
AUDIO="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$OUT")"
[ "$WIDTH" = "720" ] && [ "$HEIGHT" = "1280" ] || { echo "FAIL: dimensions ${WIDTH}x${HEIGHT}"; exit 1; }
awk -v d="$DURATION" 'BEGIN { exit !(d >= 9.8 && d <= 10.3) }' || { echo "FAIL: duration $DURATION"; exit 1; }
[ -n "$AUDIO" ] || { echo "FAIL: audio missing"; exit 1; }
echo "PASS: motion-graphics Short rendered and validated"
echo "Duration: $DURATION s | Resolution: ${WIDTH}x${HEIGHT} | Audio: $AUDIO"
echo "Output: $OUT"
