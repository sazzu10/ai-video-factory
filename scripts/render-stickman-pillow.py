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
        phase = t * 2 * math.pi * 1.15
        im = Image.new("RGB", (W, H), (16, 22, 47))
        d = ImageDraw.Draw(im)

        cx = 125 + 42 * t
        bob = 2.0 * (1 - math.cos(2 * phase)) / 2
        head_r = 43
        hx, hy = cx, 340 + bob
        white, accent, joint = (245, 248, 255), (50, 214, 197), (255, 200, 87)
        width = 13

        d.ellipse((hx-head_r, hy-head_r, hx+head_r, hy+head_r), fill=accent)
        d.ellipse((hx-15, hy-7, hx-7, hy+1), fill=(16,22,47))
        d.ellipse((hx+7, hy-7, hx+15, hy+1), fill=(16,22,47))
        d.arc((hx-17, hy-2, hx+17, hy+22), 10, 170, fill=(16,22,47), width=4)

        neck, shoulder, hip = (cx, hy+head_r), (cx, 435+bob), (cx, 625+bob)

        def line(a, b, fill=white, w=width):
            d.line((int(a[0]), int(a[1]), int(b[0]), int(b[1])), fill=fill, width=w)
            r = w // 2
            for p in (a, b):
                d.ellipse((int(p[0]-r), int(p[1]-r), int(p[0]+r), int(p[1]+r)), fill=fill)

        line(neck, shoulder, accent, 16)
        line(shoulder, hip, white, 17)

        # Arms counter-swing against the legs with a readable elbow bend.
        swing = 34 * math.sin(phase)
        elbow_l, hand_l = (cx-48+swing*.28, 510+bob), (cx-56+swing, 578+bob)
        elbow_r, hand_r = (cx+48-swing*.28, 510+bob), (cx+56-swing, 578+bob)
        for a, b in ((shoulder, elbow_l), (elbow_l, hand_l),
                     (shoulder, elbow_r), (elbow_r, hand_r)):
            line(a, b)
        for x, y in (hand_l, hand_r):
            d.ellipse((int(x-10), int(y-10), int(x+10), int(y+10)), fill=joint)

        # Wide, non-crossing gait: left and right feet stay on separate tracks.
        # A smaller stride prevents the feet and lower legs from overlapping.
        ground_y = 950
        s = math.sin(phase)
        stride = 20 * s
        lift_l = 30 * max(0, s) ** 0.8
        lift_r = 30 * max(0, -s) ** 0.8
        foot_l = (cx - 62 + stride, ground_y - lift_l)
        foot_r = (cx + 62 - stride, ground_y - lift_r)
        bend_l = 12 * max(0, s)
        bend_r = -12 * max(0, -s)
        knee_l = (cx - 34 + stride * 0.20 + bend_l, 785 + bob - lift_l * 0.35)
        knee_r = (cx + 34 - stride * 0.20 + bend_r, 785 + bob - lift_r * 0.35)
        for a, b in ((hip, knee_l), (knee_l, foot_l),
                     (hip, knee_r), (knee_r, foot_r)):
            line(a, b)
        shoe_l = 1 if s >= 0 else -1
        shoe_r = -shoe_l
        d.line((int(foot_l[0]-2), int(foot_l[1]), int(foot_l[0]+15*shoe_l), int(foot_l[1])),
               fill=white, width=10)
        d.line((int(foot_r[0]-2), int(foot_r[1]), int(foot_r[0]+15*shoe_r), int(foot_r[1])),
               fill=white, width=10)
        d.line((35, ground_y+8, 685, ground_y+8), fill=(68,83,120), width=4)
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
