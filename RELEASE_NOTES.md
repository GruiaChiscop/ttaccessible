## v1.7.0-beta.6 (build 37) — 2026-06-24

This is a **beta** release, for testing new changes before they ship to everyone. To receive beta updates, turn on **Include beta versions** in Preferences › General.

This beta is a focused VoiceOver and accessibility pass, contributed by Rocco Fiorentino.

## Accessibility & VoiceOver

- **The app is now called tt-Accessible.** The previous run-together name was mispronounced by VoiceOver and some synthesizers (notably Eloquence). The new spelling reads correctly. Nothing else changes — your servers, settings and recordings stay exactly where they were.
- **VoiceOver press (VO-Space) now joins servers and channels.** Pressing a server in the list, or a channel in the tree, with VoiceOver now connects or joins just like pressing Return — no need to leave VoiceOver to click.
- **Cleaner Preferences navigation.** The settings sidebar no longer reads duplicate labels or its icons, each settings page is announced as a named area, and Escape now closes the Preferences window.
- **Less repetition.** The volume dialog no longer reads the percentage twice, your display name is no longer read twice when it matches your username, and the per-sound switches are grouped into a single VoiceOver element instead of one per word.
- **Hear-myself button announces its state.** The Hear myself toolbar button now reports as selected to VoiceOver when it's on.

## Install

If you have beta updates enabled, tt-Accessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.7.0-beta.6-37.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
