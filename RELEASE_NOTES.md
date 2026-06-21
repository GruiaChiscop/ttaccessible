## v1.7.0-beta.3 (build 34) — 2026-06-21

This is a **beta** release, for testing new changes before they ship to everyone. To receive beta updates, turn on **Include beta versions** in Preferences › General.

## Fixes

- **VoiceOver announces volume changes again.** When you adjust the microphone gain or output volume sliders, VoiceOver now speaks the new value right away instead of repeating the previous one. Thanks to Gabriel for reporting this.

## Also in this beta

- **Faster launch.** The app paused for a moment when it started up. That pause is gone — ttaccessible now opens straight away.
- **Clearing your nickname keeps you connected.** When you change your nickname (F5) and leave the field empty, ttaccessible now falls back to your default nickname from settings instead of showing a "nickname cannot be empty" error.
- **Sign in with a BearWare account.** Connect to servers that use BearWare web login (bearware.dk) without creating a separate account on each one. Set up your free BearWare account once in **Preferences › BearWare**, then turn on **Use BearWare web login** for any server that supports it. This feature is still looking for testers — feedback is very welcome via Help › Contact the Developer.

## Install

If you have beta updates enabled, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.7.0-beta.3-34.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
