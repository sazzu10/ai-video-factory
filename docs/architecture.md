# Architecture and implementation gates

## Runtime split

- **Termux controller:** lightweight Node.js orchestration, job manifests, local validation and user-controlled handoff.
- **Motion graphics:** local FFmpeg when the installed build supports the required filters and encoders.
- **Cartoon animation:** optional remote image-to-video or compatible GPU runtime. Android CPU-only rendering is not assumed to run Wan2GP.
- **Publishing:** intentionally out of scope for the first prototype. Do not copy credentials or publisher internals from another repository.

## Genuine animation acceptance rule

A still image with only zoom, pan, crop or camera movement fails the cartoon-animation test. A successful cartoon test must show character/pose/limb/object-state changes across frames, and should be reviewed visually.

## Stages

1. Render one 10-second 720x1280 MP4 with moving graphic elements and audio.
2. Validate MP4 playback, duration, dimensions, audio and actual changing frames.
3. Select and test a hosted image-to-video option only after confirming its current free-tier and input/output limits.
4. Add a shared job manifest, retry-safe status tracking and error reporting.
5. Consider a manual export/handoff to the existing YouTube agent after prototype quality is accepted.

## Resource policy

- Never download large model weights to the phone without an explicit resource check.
- Never assume free cloud GPU uptime or unlimited free inference.
- Do not publish automatically during development.
- Keep secrets in local environment files excluded from Git.
