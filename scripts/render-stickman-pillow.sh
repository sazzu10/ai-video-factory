#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
command -v python >/dev/null 2>&1 || { echo "FAIL: Python missing. Install with: pkg install python"; exit 1; }
command -v ffmpeg >/dev/null 2>&1 || { echo "FAIL: FFmpeg missing. Install with: pkg install ffmpeg"; exit 1; }
python -c 'from PIL import Image, ImageDraw' >/dev/null 2>&1 || {
  echo "Pillow is required for this renderer."
  echo "Install once with: python -m pip install pillow"
  exit 1
}
exec python scripts/render-stickman-pillow.py
