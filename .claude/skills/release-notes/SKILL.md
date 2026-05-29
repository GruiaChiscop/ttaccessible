---
name: release-notes
description: Draft release notes for a new ttaccessible version. Use this skill whenever the user is preparing a release, asks "what changed since v1.X", wants a summary of recent work, mentions RELEASE_NOTES.md, asks for an AppleVis forum post, or is about to tag/publish — even when they don't explicitly say "release notes". Scans `git log <prev-tag>..HEAD`, checks open PRs to avoid duplicating in-flight fixes, writes in English (never French), and includes the direct GitHub asset URL.
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
