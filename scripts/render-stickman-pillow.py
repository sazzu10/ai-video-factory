#!/usr/bin/env python3
"""Render a procedural walking stickman to MP4 via Pillow + FFmpeg."""
import math
import os
import shutil
import subprocess
import sys

try:
    from PIL import Image, ImageDraw
except ImportError:
    sys.exit("FAIL: Pillow missing. Install in Termux with: python -m pip install pillow")

ffmpeg = shutil.which("ffmpeg")
ffprobe = shutil.which("ffprobe")
if not ffmpeg or not ffprobe:
    sys.exit("FAIL: ffmpeg/ffprobe missing. Install with: pkg install ffmpeg")

W, H, FPS, SECONDS = 720, 1280, 24, 10
OUT = "output/stickman-pillow.mp4"
os.makedirs("output", exist_ok=True)

cmd = [
    ffmpeg, "-y", "-hide_banner", "-loglevel", "error",
    "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{W}x{H}",
    "-r", str(FPS), "-i", "pipe:0",
    "-f", "lavfi", "-i", f"sine=frequency=440:sample_rate=44100:duration={SECONDS}",
    "-map", "0:v:0", "-map", "1:a:0", "-t", str(SECONDS),
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac",
    "-b:a", "128k", "-movflags", "+faststart", OUT
]
proc = subprocess.Popen(cmd, stdin=subprocess.PIPE)
try:
    for i in range(FPS * SECONDS):
        t = i / FPS
        phase = t * 2 * math.pi * 1.8
        im = Image.new("RGB", (W, H), (16, 22, 47))
        d = ImageDraw.Draw(im)

        # Character travels across the scene; keep the gait readable.
        cx = 115 + 45 * t
        bob = 4 * abs(math.sin(phase))
        head_r = 43
        head_c = (cx, 340 + bob)
        white = (245, 248, 255)
        accent = (50, 214, 197)
        joint = (255, 200, 87)
        width = 13

        hx, hy = head_c
        d.ellipse((hx-head_r, hy-head_r, hx+head_r, hy+head_r), fill=accent)
        d.ellipse((hx-15, hy-7, hx-7, hy+1), fill=(16,22,47))
        d.ellipse((hx+7, hy-7, hx+15, hy+1), fill=(16,22,47))
        d.arc((hx-17, hy-2, hx+17, hy+22), 10, 170, fill=(16,22,47), width=4)

        neck = (cx, hy + head_r)
        shoulder = (cx, 435 + bob)
        hip = (cx, 625 + bob)

        def line(a, b, fill=white, w=width):
            d.line((int(a[0]), int(a[1]), int(b[0]), int(b[1])), fill=fill, width=w)
            r = w // 2
            for p in (a, b):
                d.ellipse((int(p[0]-r), int(p[1]-r), int(p[0]+r), int(p[1]+r)), fill=fill)

        line(neck, shoulder, accent, 16)
        line(shoulder, hip, white, 17)

        # Opposing arm swing, attached at shoulder and elbow.
        swing = 42 * math.sin(phase)
        elbow_l = (cx - 48 - swing * 0.35, 520 + bob)
        hand_l = (cx - 65 - swing, 590 + bob)
        elbow_r = (cx + 48 + swing * 0.35, 520 + bob)
        hand_r = (cx + 65 + swing, 590 + bob)
        line(shoulder, elbow_l)
        line(elbow_l, hand_l)
        line(shoulder, elbow_r)
        line(elbow_r, hand_r)
        for p in (hand_l, hand_r):
            x, y = p
            d.ellipse((int(x-10), int(y-10), int(x+10), int(y+10)), fill=joint)

        # Alternating leg swing. One foot stays on the ground while the
        # opposite foot lifts, reducing the obvious floating-foot effect.
        stride = 68 * math.sin(phase)
        lift_l = 34 * max(0, math.sin(phase))
        lift_r = 34 * max(0, -math.sin(phase))
        ground_y = 950
        knee_l = (cx - 34 + stride * 0.42, 780 + bob - lift_l * 0.45)
        foot_l = (cx - 42 + stride, ground_y - lift_l)
        knee_r = (cx + 34 - stride * 0.42, 780 + bob - lift_r * 0.45)
        foot_r = (cx + 42 - stride, ground_y - lift_r)
        line(hip, knee_l)
        line(knee_l, foot_l)
        line(hip, knee_r)
        line(knee_r, foot_r)

        # Ground baseline: feet in stance phase touch this line.
        d.line((35, ground_y + 8, 685, ground_y + 8), fill=(68, 83, 120), width=4)
        proc.stdin.write(im.tobytes())
    proc.stdin.close()
    code = proc.wait()
    if code:
        sys.exit(f"FAIL: ffmpeg encoder exited {code}")
except BrokenPipeError:
    proc.wait()
    sys.exit("FAIL: FFmpeg closed the frame pipe; check FFmpeg output and codecs.")

def probe(args):
    return subprocess.check_output([ffprobe, "-v", "error", *args], text=True).strip()

duration = float(probe(["-show_entries", "format=duration", "-of", "default=noprint_wrappers=1:nokey=1", OUT]))
size = probe(["-select_streams", "v:0", "-show_entries", "stream=width,height", "-of", "csv=s=x:p=0", OUT])
audio = probe(["-select_streams", "a:0", "-show_entries", "stream=codec_name", "-of", "csv=p=0", OUT])
if size != "720x1280" or not 9.8 <= duration <= 10.3 or not audio:
    sys.exit(f"FAIL: validation duration={duration}, size={size}, audio={audio}")
print("PASS: Pillow stickman rendered; metadata validated")
print(f"Duration: {duration:.3f}s | Resolution: {size} | Audio: {audio}")
print(f"Output: {OUT}")
