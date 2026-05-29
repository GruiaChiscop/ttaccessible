Chat accessibility polish: keyboard copy and VoiceOver-reachable links.

## Fixed

- **Cmd+C now copies the selected chat message** — works in both the channel chat and the private messages window. Previously, copying a message required right-click → Copy Message; the shortcut shown next to the menu item did nothing on its own.
- **Links inside chat messages are reachable from VoiceOver** — URLs detected in a message are exposed as accessibility actions on its row. Move the VoiceOver cursor to a message containing a link, press VO+Cmd+Space to open the actions rotor, then choose "Open link: …" to launch it. Mouse-clicking a link in the text continues to work as before.

## Install

If you're on 1.3.0, 1.3.1, or 1.3.2, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.3.3-25.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
