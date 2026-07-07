## v1.7.0-beta.10 (build 41) — 2026-07-07

This is a **beta** release, for testing new changes before they ship to everyone. To receive beta updates, turn on **Include beta versions** in Preferences › General.

### Highlights
- **Fast connecting is back.** On Macs with several audio devices, connecting to a server had crept back up to around 13 seconds — this build makes it near-instant again.

### What's new

**Connecting is quick again.** A start-up speed-up added a few betas ago wasn't actually making it into the released builds. So on setups with a lot of audio devices — interfaces, virtual devices, headsets — opening a connection could stall for roughly 13 seconds before anything happened, while simpler setups were fine. That's now fixed at the root: the optimization is baked into every build for good, and connecting is back to being near-instant.

Nothing else changes in this build — same features and audio as beta.9.

## Install

If you have beta updates enabled, tt-Accessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.7.0-beta.10-41.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
