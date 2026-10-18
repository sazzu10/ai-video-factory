# AI Video Factory

A separate ₹0-first project for producing vertical YouTube Shorts with two pipelines:

- **Motion graphics:** animated text and shapes rendered to MP4.
- **Cartoon animation:** genuine image-to-video generation through a compatible hosted inference service or available GPU runtime.

Android Termux is the lightweight controller. Heavy AI video generation is not assumed to run locally on Android.

## Current prototype

The first milestone is a 10-second, 720x1280 motion-graphics MP4 with moving shapes, text and audio.

### Termux quick start

```sh
git clone https://github.com/sazzu10/ai-video-factory.git
cd ai-video-factory
pkg install ffmpeg
chmod +x scripts/render-motion-short.sh
./scripts/render-motion-short.sh
```

The script checks FFmpeg's `drawtext` filter and a font file, renders `output/motion-short.mp4`, then validates duration, resolution and audio with FFprobe when available. If a dependency is missing, it reports the blocker.

## Project boundaries

- This repository is separate from `youtube-automation-agent`; do not merge or modify that project.
- Never commit API keys, OAuth tokens or personal credentials.
- Do not auto-publish during development.
- Still-image zoom/pan is not genuine character animation.
- Free GPU and hosted inference availability is variable; unlimited free generation is not promised.

## Roadmap

1. Render and validate one motion-graphics Short.
2. Visually inspect actual changing frames.
3. Test one genuine cartoon image-to-video clip using a compatible runtime.
4. Add a shared job manifest and robust status/error tracking.
5. Only after quality checks, add an explicit user-controlled handoff to the existing publishing agent.

See [architecture notes](docs/architecture.md).
