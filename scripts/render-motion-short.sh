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

# Ten seconds, 720x1280, 24 fps. Moving shapes and text are rendered as
# changing frames; this is motion graphics, not character animation.
if ! ffmpeg -hide_banner -filters 2>/dev/null | grep -q drawtext; then
  echo "FAIL: this FFmpeg build lacks the drawtext filter." >&2
  echo "Use an FFmpeg build with libfreetype, then rerun this script." >&2
  exit 1
fi

FONT=""
for candidate in \
  "$PREFIX/share/fonts/TTF/DejaVuSans.ttf" \
  "$PREFIX/share/fonts/dejavu/DejaVuSans.ttf" \
  "/system/fonts/Roboto-Regular.ttf"; do
  if [ -f "$candidate" ]; then FONT="$candidate"; break; fi
done
if [ -z "$FONT" ]; then
  echo "FAIL: no supported font file found. Install a font package or update FONT in this script." >&2
  exit 1
fi

FONT_ESCAPED="$(printf '%s' "$FONT" | sed "s/:/\\\\:/g")"
ffmpeg -y -hide_banner -loglevel warning \
  -f lavfi -i "color=c=0x10162f:s=720x1280:r=24:d=10" \
  -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=10" \
  -vf "drawbox=x='(mod(t*170,900)-180)':y=210:w=180:h=180:color=0x32d6c5@0.85:t=fill,drawbox=x='(700-mod(t*120,900))':y=850:w=140:h=140:color=0xffc857@0.9:t=fill,drawtext=fontfile='$FONT_ESCAPED':text='IDEA TO VIDEO':fontcolor=white:fontsize=54:x=(w-text_w)/2:y=470,drawtext=fontfile='$FONT_ESCAPED':text='MOTION GRAPHICS TEST':fontcolor=0x32d6c5:fontsize=27:x=(w-text_w)/2:y=545,drawtext=fontfile='$FONT_ESCAPED':text='10 SECOND PROTOTYPE':fontcolor=white:fontsize=25:x=(w-text_w)/2:y=1160" \
  -map 0:v:0 -map 1:a:0 -t 10 -r 24 -c:v libx264 -pix_fmt yuv420p \
  -c:a aac -b:a 128k -movflags +faststart "$OUT"

if ! command -v ffprobe >/dev/null 2>&1; then
  echo "WARN: ffprobe not found; video was rendered but full validation is incomplete."
  echo "Output: $OUT"
  exit 0
fi

DURATION="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")"
WIDTH="$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$OUT")"
HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$OUT")"
AUDIO="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$OUT")"

[ "$WIDTH" = "720" ] && [ "$HEIGHT" = "1280" ] || { echo "FAIL: unexpected dimensions ${WIDTH}x${HEIGHT}"; exit 1; }
awk -v d="$DURATION" 'BEGIN { exit !(d >= 9.8 && d <= 10.3) }' || { echo "FAIL: unexpected duration $DURATION"; exit 1; }
[ -n "$AUDIO" ] || { echo "FAIL: audio stream missing"; exit 1; }

echo "PASS: rendered and validated motion-graphics Short"
echo "Duration: $DURATION seconds | Size: ${WIDTH}x${HEIGHT} | Audio: $AUDIO"
echo "Output: $OUT"
