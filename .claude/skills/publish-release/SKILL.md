---
name: publish-release
description: End-to-end workflow to build, sign, notarize, staple, and publish a ttaccessible release via `./build.sh --release` and the Sparkle appcast. User-triggered only — has side effects (binary publication, GitHub release, appcast push).
disable-model-invocation: true
---

# Publish a release

This is the user-triggered end-to-end release workflow. Side-effectful steps (signing, notarizing, publishing) — never run without explicit instruction.

## Prerequisites

- Version bump committed: update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `App/ttaccessible.xcodeproj/project.pbxproj`.
- `RELEASE_NOTES.md` updated (English). Use the `release-notes` skill if not already done.
- Notarytool keychain profile `ttaccessible-notary` is stored.
- On `main`, working tree clean.

## 1. Build, sign, notarize, publish

```bash
./build.sh --release
```

This:
- Builds Release with Xcode.
- Re-signs with `Developer ID Application`.
- Notarizes via `ttaccessible-notary` profile.
- Staples the ticket.
- Zips the artifact to `BuildArtifacts/`.
- Stages the zip + HTML notes + `appcast.xml` to the appcast staging dir.
- Pushes a draft GitHub release.

If you only need to fix release notes after publish (no binary change): re-render the HTML and run `gh release edit` — no rebuild or re-notarize required.

## 2. Commit and push the appcast

The appcast/HTML in `docs/` is served by GitHub Pages. Push the updated files to `main` so Sparkle clients pick up the update.

## 3. Publish the GitHub release

Verify the draft release on GitHub, attach the zip if not already uploaded, then publish.

## 4. Verify

- Direct asset URL resolves: `https://github.com/math65/ttaccessible/releases/download/v<X.Y.Z>/ttaccessible-<X.Y.Z>.zip`
- Appcast XML loads at the GitHub Pages URL and lists the new version.
- Spot-check the in-app updater on a previous-version install.

## 5. Announce

Post to AppleVis (see `release-notes` skill for formatting rules) and any relevant Slack/forum channels.
