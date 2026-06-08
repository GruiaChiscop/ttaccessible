---
name: release-notes
description: Draft release notes for a new ttaccessible version. Use this skill whenever the user is preparing a release, asks "what changed since v1.X", wants a summary of recent work, mentions RELEASE_NOTES.md, asks for an AppleVis forum post, or is about to tag/publish — even when they don't explicitly say "release notes". Scans `git log <prev-tag>..HEAD`, checks open PRs to avoid duplicating in-flight fixes, writes the English RELEASE_NOTES.md (GitHub body + Sparkle fallback) AND the French RELEASE_NOTES.fr.md (localized Sparkle notes), and includes the direct GitHub asset URL.
---

# Release notes workflow

Always run these steps in order. Do not rely on session memory for what shipped — query git.

## 1. Identify the prior tag

```bash
git tag --sort=-v:refname | head -5
```

Pick the most recent published tag (e.g. `v1.3.3`). The new release is the next semver.

## 2. Scan commits since the prior tag

```bash
git log <prev-tag>..HEAD --oneline --no-merges
```

Group commits into themes: fixes, accessibility, audio, UX, release plumbing. Skip pure release-prep commits ("Bump to X", "Update appcast") in user-facing notes.

## 3. Check open PRs

```bash
gh pr list --state open --json number,title,headRefName,author
```

If a PR addresses something you're about to claim as fixed, flag it — the contributor may have a competing approach. Don't auto-claim it as your fix.

## 4. Write the notes in English

`RELEASE_NOTES.md` and the GitHub release body are always English, not French. Structure:

```markdown
## v<X.Y.Z> (build <N>) — <YYYY-MM-DD>

### Highlights
- One-sentence headline of the most impactful change.

### Fixes
- Bullet per fix, prefixed with the area (Audio, Chat, VoiceOver, etc.).

### Other changes
- Smaller polish items.

### Download
[ttaccessible-<X.Y.Z>.zip](https://github.com/math65/ttaccessible/releases/download/v<X.Y.Z>/ttaccessible-<X.Y.Z>.zip)
```

Always include the **direct asset URL**, not just the release page link.

### Tone & wording — write for the user, not the commit log

Release notes are read by VoiceOver users deciding whether to update, not by
engineers. Translate each change into the symptom the user felt and what is
different now. Keep it natural and plain.

- **Lead with the user-visible effect**, not the mechanism. "Switching audio
  devices works again" — not "fixed the suppression-window early return".
- **Cut internal jargon.** No CoreAudio/AUHAL/AEC-tap/snapshot/churn/
  suppression-window/route-change vocabulary, no class or function names, no
  file paths. If a term names something the user can't see or act on, drop it
  or replace it with a plain phrase ("echo cancellation starting up", not
  "the AEC tap teardown").
- **Avoid literal translations of code-speak.** "device-list churn" →
  "routine changes in the audio device list"; "no-op" → "had no effect".
- **One symptom per bullet**, bolded lead clause, then a plain-language
  explanation of before → after. Don't merge unrelated fixes into one bullet.
- **Read it aloud test**: if a sentence sounds like a changelog entry or a
  PR title, rewrite it as something you'd say to a non-technical friend.
- The French file follows the same tone (see 4b) — natural French, not a
  word-for-word calque of the English.

## 4b. Write the French notes (`RELEASE_NOTES.fr.md`)

Sparkle shows localized release notes during updates: `build.sh` renders
`RELEASE_NOTES.fr.md` to `docs/<basename>.fr.html`, and `generate_appcast`
emits a `<sparkle:releaseNotesLink xml:lang="fr">` automatically. French users
see the French notes; everyone else falls back to the English `.html`.

- Translate `RELEASE_NOTES.md` into `RELEASE_NOTES.fr.md` at the repo root.
- Use **vouvoiement** ("vous", never "tu") — same rule as app-shipped French strings.
- Keep the structure and the same `.zip` filename in the Install section.
- This file is **only** for the in-app Sparkle dialog. The GitHub release body
  and AppleVis post stay English — do not publish the French version there.
- If you skip `RELEASE_NOTES.fr.md`, the build still works: Sparkle just shows
  English to everyone (the unsuffixed `.html` fallback).

## 5. Commit-issue linkage

- For commits already merged to `main` before the release: reference issues with `Refs #N`.
- For PRs or post-release confirmation: use `Fixes #N` / `Closes #N` so GitHub auto-closes.
- Push early, close issues late.

## 6. AppleVis forum post (optional)

If announcing on AppleVis, the post uses different formatting rules:

- Subject line: 64 characters max.
- Headings: H4 or lower only (H1–H3 are reserved).
- Body is Markdown.
- Include a clickable direct asset URL, not just the release page.

Draft the AppleVis version separately — do not reuse the GitHub body verbatim.
