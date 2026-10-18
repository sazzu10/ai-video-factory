# AI Video Factory

A separate ₹0-first project for producing vertical YouTube Shorts with two pipelines:

- **Motion graphics:** animated shapes and effects rendered to MP4; text overlays can be added in a later renderer.
- **Cartoon animation:** genuine image-to-video generation through a compatible hosted inference service or available GPU runtime.

Android Termux is the lightweight controller. Heavy AI video generation is not assumed to run locally on Android.

## Current prototype

The first milestone is a 10-second, 720x1280 motion-graphics MP4 with moving shapes and audio. The baseline renderer deliberately avoids FFmpeg's optional `drawtext` filter, which may be absent from Android builds.

### Termux quick start

```sh
git clone https://github.com/sazzu10/ai-video-factory.git
cd ai-video-factory
pkg install ffmpeg
chmod +x scripts/render-motion-short.sh
./scripts/render-motion-short.sh
```

The script renders `output/motion-short.mp4`, then validates duration, resolution and audio with FFprobe when available. If FFmpeg is missing, it reports the blocker.

## Project boundaries

- This repository is separate from `youtube-automation-agent`; do not merge or modify that project.
- Never commit API keys, OAuth tokens or personal credentials.
- Do not auto-publish during development.
- Still-image zoom/pan is not genuine character animation.
- Free GPU and hosted inference availability is variable; unlimited free generation is not promised.

## Roadmap

1. Render and validate one motion-graphics Short.
2. Visually inspect actual changing frames.
3. Add a text overlay path that works on Android without relying on unavailable FFmpeg filters.
4. Test one genuine cartoon image-to-video clip using a compatible runtime.
5. Add a shared job manifest and robust status/error tracking.
6. Only after quality checks, add an explicit user-controlled handoff to the existing publishing agent.

See [architecture notes](docs/architecture.md).
