**ttaccessible now updates itself.** This release migrates the app from a homemade updater to [Sparkle](https://sparkle-project.org), the framework used by most third-party Mac apps. Once you're on 1.1.0, future updates install on a click — no more downloading a zip, unzipping, and dragging the app to /Applications.

## What's new

- **Automatic updates.** Sparkle checks for new versions once every 24 hours in the background. When one is available, you get its release notes in a native dialog. Click **Install Update**, the app quits, the new version swaps in, and the app relaunches — usually under 10 seconds end to end.
- **Manual check anytime.** *ttaccessible → Check for Updates…* in the menu bar (Cmd+, then look around if it moves).
- **Auto-check toggle.** *Preferences → General → Updates → Check for updates automatically*. On by default. Disable it if you want strict manual control.
- **Beta channel.** *Preferences → General → Updates → Include beta versions*. Off by default. Turn it on if you want to test pre-release builds as soon as they ship.

## One-time migration step

If you're on 1.0.2 or earlier, the old in-app updater will offer 1.1.0 as a manual download — that's the same flow you've used until now: download the zip, unzip, drag into /Applications. Do this once.

From 1.1.0 onward, Sparkle takes over. You won't need to download zips by hand again.

## How updates are verified

Every update is signed with an EdDSA key whose public counterpart ships inside ttaccessible itself. Sparkle refuses to install anything that doesn't match. The app is also still sandboxed, notarized by Apple, and stapled — same security guarantees as before, no relaxations.

## Install

1. Download `ttaccessible-1.1.0-17.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.

After this, you're done with manual downloads.
