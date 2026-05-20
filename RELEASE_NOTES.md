Small Sparkle quality-of-life update.

## Fixed

- **Update check on every launch.** Sparkle's default behavior is to check at most once every 24 hours, even across app restarts. ttaccessible now also triggers a silent background check ~3 seconds after each launch — so if a release drops between scheduled checks, you see it the next time you open the app instead of waiting up to a day. The auto-check preference still gates everything; if you've turned it off, no launch check either.

## Install

If you're already on 1.1.0, ttaccessible will install this update for you — no action needed. Otherwise:

1. Download `ttaccessible-1.1.1-18.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
