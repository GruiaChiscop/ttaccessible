Chat accessibility polish: keyboard copy and VoiceOver-reachable links.

## Fixed

- **Cmd+C now copies the selected chat message** — works in both the channel chat and the private messages window. Previously, copying a message required right-click → Copy Message; the shortcut shown next to the menu item did nothing on its own.
- **Links inside chat messages are reachable from VoiceOver** — URLs detected in a message are exposed as accessibility actions on its row. Move the VoiceOver cursor to a message containing a link, press VO+Cmd+Space to open the actions rotor, then choose "Open link: …" to launch it. Mouse-clicking a link in the text continues to work as before.
- **Microphone preview no longer freezes on duplex audio interfaces** — when the same device was set as both the system input and output (e.g. Komplete Audio 6 MK2), starting the preview in Preferences > Audio could hang the app. Playback is now started before capture so the output side doesn't wait on a device the input side has already claimed; preview no longer tears down the connection's microphone engine via a spurious device-change restart either.

## Install

If you're on 1.3.0, 1.3.1, or 1.3.2, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.3.3-25.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
