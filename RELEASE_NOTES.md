## v1.7.0-beta.8 (build 39) — 2026-06-25

This is a **beta** release, for testing new changes before they ship to everyone. To receive beta updates, turn on **Include beta versions** in Preferences › General.

### Highlights
- **Noise reduction, on its own.** You can now clean up background noise from your microphone without turning on echo cancellation.
- **Hear your own media.** When you stream a music or audio file to a channel, you finally hear it too — not just everyone else.

### What's new

**Noise reduction without echo cancellation.** Until now, the microphone's noise reduction only came bundled with echo cancellation — all or nothing. Preferences › Audio now has a single **Microphone processing** menu with three clear choices:

- **None** — clean passthrough, no processing.
- **Noise reduction** — quiets background hiss, fans, and room noise. No echo cancellation, so nothing else gets in the way.
- **Echo cancellation + noise reduction** — the full treatment for when you're on speakers instead of headphones (echo cancellation always keeps noise reduction on, because it needs it to work well).

Switch between them anytime — even mid-conversation — and the change takes effect right away. No need to stop and restart your microphone.

**You can hear the media you stream.** When you streamed a music or audio file into a channel, everyone else could hear it, but you couldn't hear your own playback. Now you do — smoothly, alongside the people in your channel. The playback controls (play, pause, volume) work just as before; the broadcast volume slider still sets the level everyone else hears.

### Worth knowing
Both changes touch the audio engine that was rebuilt in beta.7. It's solid in daily use, but that's what the beta is for — put it through its paces and tell us how it holds up.

## Install

If you have beta updates enabled, tt-Accessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.7.0-beta.8-39.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
