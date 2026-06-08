More reliable audio device switching, multi-server `.tt` import, and update notes that now follow your language.

## Fixed

- **Switching the input or output device in Preferences works again** — picking a new device while audio was active had become a no-op. It now applies immediately, even when you change devices twice in quick succession.
- **Fewer spurious audio restarts** — routine changes in the audio device list (Continuity handoff, virtual devices, echo cancellation starting up) no longer restart the whole sound system every time. This also stops the run of microphone-permission dialogs some users saw. Devices you pick yourself in Preferences still apply right away.
- **Importing a `.tt` file with multiple servers now imports them all** — previously only the first server in the file was added and the rest were silently dropped (#15).

## Improved

- **Update notes now follow your language** — this update window shows the notes in French for French-language users and in English for everyone else.
- Updated the Sparkle updater to 2.9.3.

## Install

If you're on 1.3.x, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.3.4-26.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
